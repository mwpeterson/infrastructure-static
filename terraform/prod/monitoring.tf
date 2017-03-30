resource "aws_sns_topic" "healthcheck_alarm" {
  provider = "aws.east1"

  name = "healthcheck-alarm-${aws_s3_bucket.bucket.id}"
}

resource "aws_cloudwatch_metric_alarm" "healthcheck_bucket" {
  provider            = "aws.east1"
  alarm_name          = "healthcheck-${aws_s3_bucket.bucket.id}-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1

  alarm_actions = ["${aws_sns_topic.healthcheck_alarm.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "healthcheck_replica" {
  provider            = "aws.east1"
  alarm_name          = "healthcheck-${aws_s3_bucket.replica.id}-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1

  alarm_actions = ["${aws_sns_topic.healthcheck_alarm.arn}"]
}

resource "aws_route53_health_check" "bucket" {
  provider              = "aws.east1"
  fqdn                  = "${aws_s3_bucket.bucket.bucket_domain_name}"
  type                  = "HTTP"
  port                  = 80
  failure_threshold     = 3
  request_interval      = 30
  resource_path         = "/index.html"
  cloudwatch_alarm_name = "${aws_cloudwatch_metric_alarm.healthcheck_bucket.alarm_name}"

  tags = {
    environment = "${var.environment}"
    terraform   = true
  }
}

resource "aws_route53_health_check" "replica" {
  provider              = "aws.east1"
  fqdn                  = "${aws_s3_bucket.replica.bucket_domain_name}"
  type                  = "HTTP"
  port                  = 80
  failure_threshold     = 3
  request_interval      = 30
  resource_path         = "/index.html"
  cloudwatch_alarm_name = "${aws_cloudwatch_metric_alarm.healthcheck_replica.alarm_name}"

  tags = {
    environment = "${var.environment}"
    terraform   = true
  }
}
