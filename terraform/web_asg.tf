# Security Group for Web EC2 Instances
resource "aws_security_group" "web_instance" {
  name        = "${var.environment}-web-instance-sg"
  description = "Security group for web tier EC2 instances"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [aws_vpc_endpoint.s3.prefix_list_id]
    description     = "Allow HTTPS to S3 Gateway Endpoint for SSM Agent"
  }

  egress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.app_alb.id]
    description     = "Allow HTTP from web ALB"
  }

  tags = {
    Name        = "${var.environment}-web-instance-sg"
    Environment = var.environment
  }
}

resource "aws_security_group_rule" "web_instance_ingress_from_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.web_instance.id
  source_security_group_id = aws_security_group.alb.id
  description              = "Allow HTTP from web ALB"
}

## Deploying this rule as a separate resource is causing terraform to constantly
## destroy and recreate this rule every apply for some reason. 
## Temporarily switched this rule to in-line to resolve.
## ToDo: figure out why this is occuring when using separate resource and fix
/* resource "aws_security_group_rule" "web_instance_egress_to_app_alb" {
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.web_instance.id
  source_security_group_id = aws_security_group.app_alb.id
  description              = "Allow HTTP to app tier ALB"
} */

resource "aws_security_group_rule" "web_instance_ssm_egress" {
  count                    = var.enable_ssm_endpoints ? 1 : 0
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.web_instance.id
  source_security_group_id = module.ssm_endpoints.vpc_endpoint_sg_id
  description              = "Allow HTTPS to SSM VPC endpoints"
}

resource "aws_iam_role" "web_instance" {
  name = "${var.environment}-web-instance-role"

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
    Name        = "${var.environment}-web-instance-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "s3_ssm_access" {
  name = "${var.environment}-s3-ssm-access"
  role = aws_iam_role.web_instance.name
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

resource "aws_iam_role_policy_attachment" "web_instance_ssm" {
  role       = aws_iam_role.web_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "web_instance" {
  name = "${var.environment}-web-instance-profile"
  role = aws_iam_role.web_instance.name
}


## Launch Template with temporary user data script for testing
## ToDo: create test app code to retreive from S3 on create
resource "aws_launch_template" "web" {
  name          = "${var.environment}-web-lt"
  image_id      = var.web_ami_id
  instance_type = var.instance_type
  user_data     = base64encode(<<-EOF
    #!/bin/bash
    # Fetch app tier hostname and write to index.html
    APP_HOSTNAME=$(curl -s --fail http://${var.app_alb_dns_name} || echo "unknown")
    echo "<h1>Hello World from $(hostname -f)</h1>" > /opt/bitnami/nginx/html/index.html
    echo "<p>$APP_HOSTNAME from the app tier also says hello!</p>" >> /opt/bitnami/nginx/html/index.html
    # Install SSM Agent via S3 endpoint
    wget https://s3.${var.aws_region}.amazonaws.com/amazon-ssm-${var.aws_region}/latest/debian_amd64/amazon-ssm-agent.deb
    dpkg -i amazon-ssm-agent.deb
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
    # Restart NGINX
    /opt/bitnami/ctlscript.sh restart nginx
    EOF
  )

  iam_instance_profile {
    name = aws_iam_instance_profile.web_instance.name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups            = [aws_security_group.web_instance.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.environment}-web-instance"
      Environment = var.environment
    }
  }
}

resource "aws_autoscaling_group" "web" {
  name                = "${var.environment}-web-asg"
  desired_capacity    = 2
  max_size            = 2
  min_size            = 2
  target_group_arns   = [aws_lb_target_group.web.arn]
  vpc_zone_identifier = aws_subnet.web[*].id

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.environment}-web-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}