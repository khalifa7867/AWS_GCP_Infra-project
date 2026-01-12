variable "aws_cluster_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "cluster_role_arn" {
  type = string 
}

variable "node_group_role_arn" {
  type = string
}



variable "private_subnet_ids" {
  type = list(string)
}

variable "public_access_cidrs" {
  type = list(string)
}

variable "kubernetes_version" {
    type    = string
    default = "1.31"
}

variable "vpc_id" {
  type = string
}

variable "node_groups" {
  type = map(object({
    instance_types = list(string)
    desired_capacity = number
    max_size = number
    min_size = number
    capacity_type = optional(string)
    disk_size = optional(number)
    labels = optional(map(string))
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })))
      tags = optional(map(string))
      user_data = optional(string)
  }))

}

variable "coredns_version" {
  type    = string
  default = ""
}

variable "kube_proxy_version" {
  type    = string
  default = ""
}

variable "vpc_cni_version" {
  type    = string
  default = ""
}


variable "enable_irsa" {
  description = "Enable IAM Roles for Service Accounts (IRSA)"
  type        = bool
  default     = true
}

