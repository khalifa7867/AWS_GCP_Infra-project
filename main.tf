
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
      desired_capacity = 0
      max_size         = 20
      min_size         = 0      # Scale to zero when idle
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

