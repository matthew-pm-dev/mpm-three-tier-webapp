resource "aws_security_group" "app_instance" {
  name        = "${var.environment}-app-instance-sg"
  description = "Security group for app tier EC2 instances"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [aws_vpc_endpoint.s3.prefix_list_id]
    description     = "Allow HTTPS to S3 Gateway Endpoint for SSM Agent"
  }

  tags = {
    Name        = "${var.environment}-app-instance-sg"
    Environment = var.environment
  }
}

resource "aws_security_group_rule" "app_instance_ingress_from_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app_instance.id
  source_security_group_id = aws_security_group.app_alb.id
  description              = "Allow HTTP from app ALB"
}

resource "aws_security_group_rule" "app_instance_egress_to_dynamodb" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app_instance.id
  source_security_group_id = aws_security_group.dynamodb_endpoint.id
  description              = "Allow HTTPS to DynamoDB VPC Endpoint"
}

resource "aws_iam_role" "app_instance" {
  name = "${var.environment}-app-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.environment}-app-instance-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "app_s3_ssm_access" {
  name = "${var.environment}-app-s3-ssm-access"
  role = aws_iam_role.app_instance.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "arn:aws:s3:::amazon-ssm-${var.aws_region}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "app_instance_ssm" {
  role       = aws_iam_role.app_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "app_instance" {
  name = "${var.environment}-app-instance-profile"
  role = aws_iam_role.app_instance.name
}

## Launch Template with temporary user data script for testing
## ToDo: create test app code to retreive from S3 on create
resource "aws_launch_template" "app" {
  name          = "${var.environment}-app-lt"
  image_id      = var.app_ami_id
  instance_type = var.instance_type
  user_data     = base64encode(<<-EOF
    #!/bin/bash
    # Create a simple Python HTTP server script
    cat << 'PY' > /home/ec2-user/server.py
    import http.server
    import socketserver
    import socket

    PORT = 80
    class Handler(http.server.SimpleHTTPRequestHandler):
        def do_GET(self):
            self.send_response(200)
            self.send_header("Content-type", "text/plain")
            self.end_headers()
            hostname = socket.getfqdn()
            self.wfile.write(hostname.encode())

    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        httpd.serve_forever()
    PY
    # Run the HTTP server as ec2-user
    nohup python3 /home/ec2-user/server.py &
    EOF
  )

  iam_instance_profile {
    name = aws_iam_instance_profile.app_instance.name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups            = [aws_security_group.app_instance.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.environment}-app-instance"
      Environment = var.environment
    }
  }
}

resource "aws_autoscaling_group" "app" {
  name                = "${var.environment}-app-asg"
  desired_capacity    = 2
  max_size            = 2
  min_size            = 2
  target_group_arns   = [aws_lb_target_group.app.arn]
  vpc_zone_identifier = aws_subnet.app[*].id

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.environment}-app-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}