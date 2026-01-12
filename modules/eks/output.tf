output "aws_eks_cluster" {
  value = aws_eks_cluster.main.id
}

output "tls_certificate-sha1_fingerprint" {
  value = data.tls_certificate.cluster[0].certificates[0].sha1_fingerprint
}

output "tls_certificate_issuer" {
  value = data.tls_certificate.cluster[0].certificates[0].issuer
}

output "cluster_security_group_id" {
  value = aws_security_group.cluster.id
}

output "aws_security_group_node_group_id" {
  value = aws_security_group.node_group.id
  
}

output "oidc_provider_arn" {
  value = var.enable_irsa ? aws_iam_openid_connect_provider.cluster[0].arn : ""
}

output "oidc_provider_url" {
  value = var.enable_irsa ? replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "") : ""
}

output "cluster_role_arn" {
  value = aws_eks_cluster.main.role_arn
}