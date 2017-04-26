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

  dimensions = {
    HealthCheckId = "${aws_route53_health_check.bucket.id}"
  }

  alarm_actions = ["${data.terraform_remote_state.global.healthcheck_alarm_topic.arn}"]
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

  dimensions = {
    HealthCheckId = "${aws_route53_health_check.replica.id}"
  }

  alarm_actions = ["${data.terraform_remote_state.global.healthcheck_alarm_topic.arn}"]
}

resource "random_id" "path" {
  byte_length = 32
}

resource "aws_s3_bucket_object" "check" {
  bucket        = "${aws_s3_bucket.bucket.id}"
  key           = "check/${random_id.path.b64}/ok"
  content       = "1"
  acl           = "public-read"
  cache_control = "no-cache, no-store"

  tags = {
    environment = "${var.environment}"
    terraform   = true
  }
}

resource "aws_route53_health_check" "bucket" {
  provider          = "aws.east1"
  fqdn              = "${aws_s3_bucket.bucket.bucket_domain_name}"
  type              = "HTTP"
  port              = 80
  failure_threshold = 3
  request_interval  = 30
  resource_path     = "/${aws_s3_bucket_object.check.id}"

  tags = {
    environment = "${var.environment}"
    terraform   = true
  }
}

resource "aws_route53_health_check" "replica" {
  provider          = "aws.east1"
  fqdn              = "${aws_s3_bucket.replica.bucket_domain_name}"
  type              = "HTTP"
  port              = 80
  failure_threshold = 3
  request_interval  = 30
  resource_path     = "/${aws_s3_bucket_object.check.id}"

  tags = {
    environment = "${var.environment}"
    terraform   = true
  }
}
