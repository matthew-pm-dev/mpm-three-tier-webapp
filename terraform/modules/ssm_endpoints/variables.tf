variable "enable_ssm_endpoints" {
  description = "Enable SSM VPC endpoints"
  type        = bool
  default     = false
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for endpoints"
  type        = list(string)
}

variable "web_instance_sg_id" {
  description = "Security group ID for web instances"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

