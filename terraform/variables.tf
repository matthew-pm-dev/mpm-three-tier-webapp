# Config Toggles

variable "enable_ssm_endpoints" {
  description = "Enable SSM VPC endpoints"
  type        = bool
  default     = false
}

variable "disable_cloudfront_caching" {
  description = "Disable CloudFront caching for testing purposes"
  type        = bool
  default     = false
}

# General Variables

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "mpm-3twa-dev"
}

variable "instance_type" {
  description = "EC2 instance type for web tier"
  type        = string
  default     = "t3.micro"
}

variable "web_ami_id" {
  description = "AMI ID for EC2 instances (Amazon Linux 2)"
  type        = string
  default     = "ami-08b00e6f894a62af3"   # Bitnami NGINX package
}

variable "app_ami_id" {
  description = "AMI ID for EC2 instances (Amazon Linux 2)"
  type        = string
  default     = "ami-0cbbe2c6a1bb2ad63"  # Amazon Linux 2 AMI for us-east-1
}

variable "app_alb_dns_name" {
  description = "DNS name of the app tier ALB"
  type        = string
  default     = "" # Used via tfvars to properly configure web tier asg user data
}
