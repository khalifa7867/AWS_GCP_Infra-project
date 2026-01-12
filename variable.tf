variable "envinorment" {
  type = string
  default = "dev"
}

variable "Project_name" {
  type = string
    default = "aws_gcp_infra_provisioning"
}

variable "region" {
  type = string
  default = "ap-south-1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
  description = "CIDR block for the VPC"
  type = string
}


variable "aws_private_subnets" {
  type = list(string)
  default = [ "10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24" ]
    description = "List of AWS subnets"
}

variable "aws_public_subnets" {
  type = list(string)
  default = [ "10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24" ]
  description = "List of AWS public subnets"
}

variable "vpc_name" {
  type = string
  default = "my-vpc"
}

variable "aws_cluster_name" {
  type = string
  default = "my_eks_cluster"
}




