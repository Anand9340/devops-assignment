
# ----------------------------------------
# Application Load Balancer
# ----------------------------------------

resource "aws_lb" "main" {
  name               = "${var.project}-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb.id
  ]

  subnets = [
    for subnet in aws_subnet.public : subnet.id
  ]

  enable_deletion_protection = false

  tags = {
    Name = "${var.project}-alb"
  }
}

# ----------------------------------------
# ALB Target Group
# ----------------------------------------

resource "aws_lb_target_group" "app" {
  name                 = "${var.project}-tg"
  port                 = 8000
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = aws_vpc.main.id
  deregistration_delay = 15

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${var.project}-tg"
  }
}

# ----------------------------------------
# ALB HTTP Listener
# Reject requests without origin header
# ----------------------------------------

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Forbidden"
      status_code  = "403"
    }
  }
}

# ----------------------------------------
# Allow CloudFront Origin Requests
# ----------------------------------------

resource "aws_lb_listener_rule" "cloudfront_only" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  condition {
    http_header {
      http_header_name = "X-Origin-Verify"

      values = [
        random_password.origin_header.result
      ]
    }
  }
}

