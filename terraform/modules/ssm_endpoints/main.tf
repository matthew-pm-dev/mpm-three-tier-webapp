resource "aws_security_group" "vpc_endpoint" {
  count       = var.enable_ssm_endpoints ? 1 : 0
  name        = "${var.environment}-vpc-endpoint-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.environment}-vpc-endpoint-sg"
    Environment = var.environment
  }
}

resource "aws_security_group_rule" "vpc_endpoint_ingress" {
  count             = var.enable_ssm_endpoints ? 1 : 0
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.vpc_endpoint[0].id
  source_security_group_id = var.web_instance_sg_id
  description       = "Allow HTTPS from web instances"
}

resource "aws_vpc_endpoint" "ssm" {
  count               = var.enable_ssm_endpoints ? 1 : 0
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = var.enable_ssm_endpoints ? [aws_security_group.vpc_endpoint[0].id] : []
  private_dns_enabled = true
  tags                = { Name = "${var.environment}-ssm-endpoint", Environment = var.environment }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  count               = var.enable_ssm_endpoints ? 1 : 0
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = var.enable_ssm_endpoints ? [aws_security_group.vpc_endpoint[0].id] : []
  private_dns_enabled = true
  tags                = { Name = "${var.environment}-ssmmessages-endpoint", Environment = var.environment }
}

resource "aws_vpc_endpoint" "ec2messages" {
  count               = var.enable_ssm_endpoints ? 1 : 0
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = var.enable_ssm_endpoints ? [aws_security_group.vpc_endpoint[0].id] : []
  private_dns_enabled = true
  tags                = { Name = "${var.environment}-ec2messages-endpoint", Environment = var.environment }
}