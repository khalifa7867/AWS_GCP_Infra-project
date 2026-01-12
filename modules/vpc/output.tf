output "vpc_cidr" {
  value = aws_vpc.my_vpc.cidr_block
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "aws_eip_ids" {
  value = aws_eip.nat_gateway_eip[*].id
  
}

output "public_subnet_cidrs" {
  value = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidrs" {
  value = aws_subnet.private[*].cidr_block
}

output "vpc_id" {
  value = aws_vpc.my_vpc.id
}