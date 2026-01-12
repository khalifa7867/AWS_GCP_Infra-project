resource "aws_kms_key" "eks" {
  description             = "KMS key for EKS cluster ${var.aws_cluster_name} encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(
    var.tags,
    {
      Name = "${var.aws_cluster_name}-eks-kms"
    }
  )
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.aws_cluster_name}-eks"
  target_key_id = aws_kms_key.eks.key_id
}


resource "aws_cloudwatch_log_group" "cloudwatch" {
  name = "/aws/eks/${var.aws_cluster_name}/cluster"
  retention_in_days = 30

    tags = var.tags
}


data "tls_certificate" "cluster" {
  count = var.enable_irsa ? 1 : 0
  url   = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "cluster" {
  count           = var.enable_irsa ? 1 : 0
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster[0].certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = merge(
    var.tags,
    {
      Name = "${var.aws_cluster_name}-oidc-provider"
    }
  )
}




resource "aws_security_group" "cluster" {
  vpc_id = var.vpc_id
name   = "${var.aws_cluster_name}-cluster-sg"


egress {

    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}

tags = merge(var.tags, {
    "Name" = "${var.aws_cluster_name}-cluster-sg"
  })

lifecycle {
    create_before_destroy = true
  }

}

resource "aws_security_group" "node_group" {
  vpc_id = var.vpc_id
name   = "${var.aws_cluster_name}-nodegroup-sg"

egress {

    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}

    lifecycle {
    create_before_destroy = true
  }


tags = merge(var.tags, {
    "Name" = "${var.aws_cluster_name}-nodegroup-sg"
    "kubernetes.io/cluster/${var.aws_cluster_name}" = "owned"
  })
}

resource "aws_security_group_rule" "cluster_to_nodegroup" {
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "6"
  source_security_group_id = aws_security_group.cluster.id
  security_group_id        = aws_security_group.node_group.id
}

resource "aws_security_group_rule" "nodegroup_to_cluster" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.node_group.id
  security_group_id        = aws_security_group.cluster.id
}

resource "aws_security_group_rule" "nodegroup_self" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  source_security_group_id = aws_security_group.node_group.id
  security_group_id        = aws_security_group.node_group.id
  
}






resource "aws_eks_cluster" "main" {
  name     = var.aws_cluster_name
  role_arn = var.cluster_role_arn
  version = var.kubernetes_version

  vpc_config {
    subnet_ids = var.private_subnet_ids
     endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs = var.public_access_cidrs
    security_group_ids = [aws_security_group.cluster.id]
  }

  encryption_config {
    provider {
      key_arn = aws_kms_key.eks.arn
    }
    resources = ["secrets"]
  }


  enabled_cluster_log_types = [ "api", "audit", "authenticator", "controllerManager", "scheduler" ]

depends_on = [ aws_cloudwatch_log_group.cloudwatch ]
  tags = var.tags
  
}


resource "aws_launch_template" "node_group_lt" {

    for_each = var.node_groups

    
  name = "${var.aws_cluster_name}-nodegroup-${each.key}-lt"

  key_name = "EKS_node_group"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = lookup(each.value, "disk_size", 20)
      volume_type = "gp3"
      iops = "3000"
      throughput = "125"
      delete_on_termination = true
      encrypted = true

    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

monitoring {
  enabled = true
}

network_interfaces {
  associate_public_ip_address = false
  delete_on_termination = true
  security_groups = [aws_security_group.node_group.id]
}

tag_specifications {
  resource_type = "instance"

tags = merge(var.tags, {
    "Name" = "${var.aws_cluster_name}-nodegroup-${each.key}-instance"
  })
}

lifecycle {
  create_before_destroy = true
}

tags = merge(var.tags, {
    "Name" = "${var.aws_cluster_name}-nodegroup-${each.key}-lt"
  })

}

resource "aws_eks_node_group" "main" {
  for_each = var.node_groups

  cluster_name    = var.aws_cluster_name
  node_group_name = "${var.aws_cluster_name}-nodegroup-${each.key}"
  node_role_arn   = var.node_group_role_arn
  subnet_ids      = var.private_subnet_ids

  scaling_config {
    desired_size = each.value.desired_capacity
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }

  launch_template {
    id      = aws_launch_template.node_group_lt[each.key].id
    version = aws_launch_template.node_group_lt[each.key].latest_version
  }

  instance_types = each.value.instance_types
  capacity_type = lookup(each.value, "capacity_type", "ON_DEMAND" )

dynamic "taint" {
  for_each = each.value.taints != null ? each.value.taints : []
  content {
    key    = taint.value.key
    value  = taint.value.value
    effect = taint.value.effect
  }
}


  labels = lookup(each.value, "labels", {} )

  tags = merge(var.tags, {
    "Name" = "${var.aws_cluster_name}-nodegroup-${each.key}"
  })

  depends_on = [ aws_eks_cluster.main ]

  lifecycle {
  ignore_changes = [ scaling_config[0].desired_size ]
  }

}

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "coredns"
  addon_version               = var.coredns_version != "" ? var.coredns_version : null
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.main]

  tags = var.tags
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "kube-proxy"
  addon_version               = var.kube_proxy_version != "" ? var.kube_proxy_version : null
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "vpc-cni"
  addon_version               = var.vpc_cni_version != "" ? var.vpc_cni_version : null
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags
}






