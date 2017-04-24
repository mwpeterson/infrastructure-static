resource "aws_lambda_permission" "cf_s3_failover_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.cf_s3_failover.arn}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${aws_sns_topic.healthcheck_alarm.arn}"
}

resource "aws_iam_role" "failover" {
  name = "iam_for_failover_sns_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function" "cf_s3_failover" {
  provider      = "aws.west2"
  function_name = "cf_s3_failover"
  handler       = "index.handler"
  role          = "${aws_iam_role.failover.arn}"
  runtime       = "nodejs6.10"
  filename      = "../../lambda/s3_failover/dist/cf_s3_failover_latest.zip"
  publish       = true
}

resource "aws_sns_topic" "healthcheck_alarm" {
  provider = "aws.east1"
  name     = "healthcheck_alarm_topic"
}

output "healthcheck_alarm_topic.arn" {
  value = "${aws_sns_topic.healthcheck_alarm.arn}"
}

resource "aws_sns_topic_subscription" "healthcheck_alarm" {
  provider  = "aws.east1"
  topic_arn = "${aws_sns_topic.healthcheck_alarm.arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.cf_s3_failover.arn}"
}
