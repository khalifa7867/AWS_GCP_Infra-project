data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_key_pair" "eks" {
  key_name = "EKS_node_group"
}


data "aws_caller_identity" "current" {}