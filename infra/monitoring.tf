
# ----------------------------------------
# SNS Topic for Alerts
# ----------------------------------------

resource "aws_sns_topic" "alerts" {
  name = "${var.project}-alerts"
}

# ----------------------------------------
# Email Subscription
# ----------------------------------------

variable "alert_email" {
  description = "Email address for CloudWatch alerts"
  type        = string
  default     = ""
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ----------------------------------------
# Backend Target 5XX Alarm
# ----------------------------------------

resource "aws_cloudwatch_metric_alarm" "target_5xx" {
  alarm_name        = "${var.project}-target-5xx"
  alarm_description = "Backend application is returning HTTP 5XX errors"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_Target_5XX_Count"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
    TargetGroup  = aws_lb_target_group.app.arn_suffix
  }

  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 5
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alerts.arn]
}

# ----------------------------------------
# ALB 5XX Alarm
# ----------------------------------------

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name        = "${var.project}-alb-5xx"
  alarm_description = "Application Load Balancer is returning HTTP 5XX errors"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_ELB_5XX_Count"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 5
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alerts.arn]
}

# ----------------------------------------
# Unhealthy Target Hosts Alarm
# ----------------------------------------

resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name        = "${var.project}-unhealthy-hosts"
  alarm_description = "Backend targets are unhealthy"

  namespace   = "AWS/ApplicationELB"
  metric_name = "UnHealthyHostCount"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
    TargetGroup  = aws_lb_target_group.app.arn_suffix
  }

  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alerts.arn]
}

