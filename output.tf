output "vpc" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "cluster_role_arn" {
  value = module.iam.cluster_role_arn
}

output "node_group_role_arn" {
  value = module.iam.node_group_role_arn
}

output "tls_certificate-sha1_fingerprint" {
  value = module.eks.tls_certificate-sha1_fingerprint
}

output "tls_certificate_issuer-output" {
  value = module.eks.tls_certificate_issuer
}

output "cluster_role_arn-output" {
  value = module.eks.cluster_role_arn
}

output "oidc_provider_arn-output" {
  value = module.eks.oidc_provider_arn
}

