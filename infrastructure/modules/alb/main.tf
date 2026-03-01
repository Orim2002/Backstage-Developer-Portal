resource "aws_lb" "main" {
  name               = "${var.environment}-backstage-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  tags = {
    Environment = var.environment
  }
}

# Target Group
resource "aws_lb_target_group" "backstage" {
  name        = "${var.environment}-backstage-tg"
  port        = 7007
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/healthcheck"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    matcher = "200-299"
  }
}

# Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backstage.arn
  }
}

# Security Group
resource "aws_security_group" "alb" {
  name   = "${var.environment}-alb-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Frontend Target Group
resource "aws_lb_target_group" "frontend" {
  name        = "${var.environment}-frontend-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path = "/"
  }
}

# Listener Rule — API traffic to backend
resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backstage.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backstage.arn
  }
}