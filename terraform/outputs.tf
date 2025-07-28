output "vpc_id" {
  value       = aws_vpc.main.id
  description = "ID of the VPC"
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "List of public subnet IDs for web ALB"
}

output "web_subnet_ids" {
  value       = aws_subnet.web[*].id
  description = "List of private subnet IDs for web tier"
}

output "app_subnet_ids" {
  value       = aws_subnet.app[*].id
  description = "List of private subnet IDs for app tier"
}

output "web_alb_dns_name" {
  value       = aws_lb.web.dns_name
  description = "DNS name of the web tier ALB"
}

output "web_asg_name" {
  value       = aws_autoscaling_group.web.name
  description = "Name of the web tier Auto Scaling Group"
}

output "app_alb_dns_name" {
  value       = aws_lb.app.dns_name
  description = "DNS name of the app tier ALB"
}

output "app_asg_name" {
  value       = aws_autoscaling_group.app.name
  description = "Name of the app tier Auto Scaling Group"
}

output "ssm_endpoint_id" {
  value       = module.ssm_endpoints.ssm_endpoint_id
  description = "ID of the SSM VPC endpoint"
}

output "ssmmessages_endpoint_id" {
  value       = module.ssm_endpoints.ssmmessages_endpoint_id
  description = "ID of the SSM Messages VPC endpoint"
}

output "ec2messages_endpoint_id" {
  value       = module.ssm_endpoints.ec2messages_endpoint_id
  description = "ID of the EC2 Messages VPC endpoint"
}

output "cloudfront_domain_name" {
  value       = aws_cloudfront_distribution.web.domain_name
  description = "Domain name of the CloudFront distribution"
}