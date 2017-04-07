resource "aws_lambda_permission" "with_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.codebuild.arn}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${aws_sns_topic.codebuild.arn}"
}

resource "aws_iam_role" "codebuild" {
  name = "iam_for_codebuild_sns_lambda"

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

resource "aws_lambda_function" "codebuild" {
  provider      = "aws.west2"
  function_name = "codebuild-sns2slack"
  handler       = "index.handler"
  role          = "${aws_iam_role.codebuild.arn}"
  runtime       = "nodejs6.10"
  filename      = "../../../sns2slack-codebuild/dist/sns2slack-codebuild_latest.zip"
  publish       = true
}

resource "aws_sns_topic" "codebuild" {
  provider = "aws.west2"
  name     = "codebuild-topic"
}

output "codebuild_topic.arn" {
  value = "${aws_sns_topic.codebuild.arn}"
}

resource "aws_sns_topic_subscription" "codebuild" {
  provider  = "aws.west2"
  topic_arn = "${aws_sns_topic.codebuild.arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.codebuild.arn}"
}
