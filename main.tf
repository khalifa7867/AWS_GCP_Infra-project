
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr           = var.vpc_cidr
  enable_nat_gateway = true
  single_nat_gateway = true
  azs                = slice(data.aws_availability_zones.available.names, 0, 3)

  aws_private_subnets = var.aws_private_subnets
  aws_public_subnets  = var.aws_public_subnets

  Project_name = var.Project_name
  envinorment  = var.envinorment
  vpc_name     = var.vpc_name

  public_subnet_tags = {
    "kubernetes.io/role/elb"                        = "1"
    "kubernetes.io/cluster/${var.aws_cluster_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"               = "1"
    "kubernetes.io/cluster/${var.aws_cluster_name}" = "shared"
  }

}


module "iam" {
  source           = "./modules/iam"
  aws_cluster_name = var.aws_cluster_name

  tags = {
    Project_name = var.Project_name
    envinorment  = var.envinorment
  }
}


module "eks" {
  source = "./modules/eks"

  aws_cluster_name    = var.aws_cluster_name
  cluster_role_arn    = module.iam.cluster_role_arn
  node_group_role_arn = module.iam.node_group_role_arn
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  public_access_cidrs = ["0.0.0.0/0"]

  enable_irsa = true


  node_groups = {
    general = {
      instance_types   = ["t3.small"]
      desired_capacity = 2
      max_size         = 3
      min_size         = 1
      capacity_type    = "ON_DEMAND"
      disk_size        = 20

      labels = {
        role = "general"
      }

      tags = {
        NodeGroup = "general"
      }
    }

    runners = {
      instance_types   = ["t3.medium"]
      desired_capacity = 1
      max_size         = 20
      min_size         = 1      # Scale to zero when idle
      capacity_type    = "SPOT" # Save 70% cost

      labels = {
        workload-type = "github-actions"
        runner-size   = "medium"
        runners       = "self-hosted"
      }

      taints = [{
        key    = "github-actions"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]

      tags = {
        NodeGroup = "runners"
      }
    }



    /*spot = {
      instance_types = ["t3.small"]
      desired_capacity = 1
      min_size       = 1
      max_size       = 3
      capacity_type  = "SPOT"
      disk_size      = 20

      labels = {
        role = "spot"
      }

      taints = [{
        key    = "spot"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]


      tags = {
        NodeGroup = "spot"
      }
    }*/

  }

  tags = {
    Project_name = var.Project_name
    envinorment  = var.envinorment
  }

  depends_on = [module.iam]


}

# GitHub Actions Runner IAM Role (IRSA)
resource "aws_iam_role" "github_runner" {
  name = "GitHubRunnerRole-${var.aws_cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider_url}:sub" = "system:serviceaccount:actions-runner-system:github-runner-sa"
            "${module.eks.oidc_provider_url}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Project_name = var.Project_name
    envinorment  = var.envinorment
  }

  depends_on = [module.eks]
}

resource "aws_iam_role_policy_attachment" "github_runner_ecr" {
  role       = aws_iam_role.github_runner.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy_attachment" "github_runner_eks" {
  role       = aws_iam_role.github_runner.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

