variable "vpc_cidr" {
  description = "default cidr value for my vpc"
    type        = string
}

variable "enable_nat_gateway" {
  type = bool
  description = "Enable NAT gateway"
}

variable "single_nat_gateway" {
  type = bool
  description = "Use a single NAT gateway"
}

variable "azs" {
  type = list(string)
  description = "azs"
}

variable "vpc_name" {
  type = string
  description = "Name of the VPC"
}

variable "envinorment" {
  type = string
}

variable "Project_name" {
  type = string
}


variable "aws_public_subnets" {
  type = list(string)
    description = "List of AWS public subnets"
}

variable "aws_private_subnets" {
  type = list(string)
    description = "List of AWS private subnets"
}

variable "public_subnet_tags" {
  type = map(string)
}

variable "private_subnet_tags" {
  type = map(string)
}