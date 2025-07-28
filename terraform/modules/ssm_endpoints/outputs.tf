output "ssm_endpoint_id" {
  value       = var.enable_ssm_endpoints ? aws_vpc_endpoint.ssm[0].id : null
  description = "ID of the SSM VPC endpoint"
}

output "ssmmessages_endpoint_id" {
  value       = var.enable_ssm_endpoints ? aws_vpc_endpoint.ssmmessages[0].id : null
  description = "ID of the SSM Messages VPC endpoint"
}

output "ec2messages_endpoint_id" {
  value       = var.enable_ssm_endpoints ? aws_vpc_endpoint.ec2messages[0].id : null
  description = "ID of the EC2 Messages VPC endpoint"
}

output "vpc_endpoint_sg_id" {
  value       = var.enable_ssm_endpoints ? aws_security_group.vpc_endpoint[0].id : null
  description = "ID of the security group for VPC endpoints"
}