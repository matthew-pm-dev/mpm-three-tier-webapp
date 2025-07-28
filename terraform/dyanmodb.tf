resource "aws_security_group" "dynamodb_endpoint" {
  name        = "${var.environment}-dynamodb-endpoint-sg"
  description = "Security group for DynamoDB VPC endpoint"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.app_instance.id]
    description     = "Allow HTTPS from app tier instances"
  }

  tags = {
    Name        = "${var.environment}-dynamodb-endpoint-sg"
    Environment = var.environment
  }
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids    = aws_route_table.app[*].id

  tags = {
    Name        = "${var.environment}-dynamodb-endpoint"
    Environment = var.environment
  }
}

resource "aws_dynamodb_table" "messages" {
  name           = "${var.environment}-messages"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "user_id"
  range_key      = "message"

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "message"
    type = "S"
  }

  tags = {
    Name        = "${var.environment}-messages"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "app_dynamodb_access" {
  name = "${var.environment}-app-dynamodb-access"
  role = aws_iam_role.app_instance.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.messages.arn
      }
    ]
  })
}