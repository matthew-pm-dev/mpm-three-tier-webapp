# Security Group for App ALB
resource "aws_security_group" "app_alb" {
  name        = "${var.environment}-app-alb-sg"
  description = "Security group for app tier ALB"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-app-alb-sg"
    Environment = var.environment
  }
}

resource "aws_security_group_rule" "app_alb_ingress_from_web" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app_alb.id
  source_security_group_id = aws_security_group.web_instance.id
  description              = "Allow HTTP from web tier instances"
}

resource "aws_security_group_rule" "app_alb_egress_to_app" {
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app_alb.id
  source_security_group_id = aws_security_group.app_instance.id
  description              = "Allow HTTP to app instances"
}

resource "aws_lb" "app" {
  name               = "${var.environment}-app-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.app_alb.id]
  subnets            = aws_subnet.app[*].id

  tags = {
    Name        = "${var.environment}-app-alb"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "app" {
  name        = "${var.environment}-app-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "${var.environment}-app-tg"
    Environment = var.environment
  }
}

resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}