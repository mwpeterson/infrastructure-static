resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-role-"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "codebuild_policy" {
  name        = "codebuild-policy"
  path        = "/service-role/"
  description = "Policy used in trust relationship with CodeBuild"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "s3:CreateBucket",
        "s3:GetObject",
        "s3:List*",
        "s3:PutObject"
      ]
    }
  ]
}
POLICY
}

resource "aws_iam_policy_attachment" "codebuild_policy_attachment" {
  name       = "codebuild-policy-attachment"
  policy_arn = "${aws_iam_policy.codebuild_policy.arn}"
  roles      = ["${aws_iam_role.codebuild_role.id}"]
}

resource "aws_codebuild_project" "codebuild-pinkimpact" {
  provider      = "aws.west2"
  name          = "codebuild-pinkimpact"
  build_timeout = "5"
  service_role  = "${aws_iam_role.codebuild_role.arn}"

  artifacts {
    type     = "S3"
    location = "${aws_s3_bucket.bucket.id}"
    name     = ""
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/eb-nodejs-4.4.6-amazonlinux-64:2.1.3"
    type         = "LINUX_CONTAINER"
  }

  source {
    type     = "GITHUB"
    location = "https://github.com/gateway-church/pinkimpact-static.git"

    auth = {
      type = "OAUTH"
    }
  }

  tags {
    env       = "${var.env}"
    terraform = true
  }
}
