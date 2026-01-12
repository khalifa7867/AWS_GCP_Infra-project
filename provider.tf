provider "aws" {
  region = var.region
  profile = "ap-south"
}

terraform {
  required_version = ">= 1.3.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}



 
