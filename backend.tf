terraform {
  backend "s3" {
    bucket = "my-terraform-awsxgcp-state-bucket"
    key    = "aws_gcp_infra_provisioning-project/terraform.tfstate"
    region = "ap-south-1"
    profile = "ap-south"
    use_lockfile = true
  }
}
