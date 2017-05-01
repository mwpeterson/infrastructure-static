resource "aws_iam_policy" "replication" {
  name = "${var.project}-${var.environment}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.bucket.arn}"
      ]
    },
    {
      "Action": [
        "s3:GetObjectVersion",
        "s3:GetObjectVersionAcl"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.bucket.arn}/*"
      ]
    },
    {
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.replica.arn}/*"
    }
  ]
}
POLICY
}

resource "aws_iam_policy_attachment" "replication" {
  name       = "${var.project}-${var.environment}"
  policy_arn = "${aws_iam_policy.replication.arn}"
  roles      = ["${data.terraform_remote_state.global.replication_role.id}"]
}

resource "aws_s3_bucket" "replica" {
  provider      = "aws.east2"
  bucket        = "${var.project}-${var.environment}-replica"
  acl           = "private"
  force_destroy = true

  versioning {
    enabled = true
  }

  tags {
    environment = "${var.environment}"
    terraform   = true
  }
}

resource "aws_s3_bucket_policy" "replica" {
  provider = "aws.east2"
  bucket   = "${aws_s3_bucket.replica.id}"

  policy = <<POLICY
{
  "Version": "2008-10-17",
  "Id": "PolicyForCloudFrontPrivateContent",
  "Statement": [
      {
          "Sid": "1",
          "Effect": "Allow",
          "Principal": {
              "AWS": "${aws_cloudfront_origin_access_identity.origin_access.iam_arn}"
          },
          "Action": "s3:GetObject",
          "Resource": "arn:aws:s3:::${aws_s3_bucket.replica.id}/*"
      }
  ]
}
POLICY
}

resource "aws_s3_bucket" "bucket" {
  provider      = "aws.west2"
  bucket        = "${var.project}-${var.environment}"
  acl           = "private"
  force_destroy = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    prefix                                 = ""
    enabled                                = true
    abort_incomplete_multipart_upload_days = 7

    noncurrent_version_transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    noncurrent_version_transition {
      days          = 60
      storage_class = "GLACIER"
    }

    noncurrent_version_expiration {
      days = 180
    }
  }

  replication_configuration {
    role = "${data.terraform_remote_state.global.replication_role.arn}"

    rules {
      id     = "${var.project}-${var.environment}"
      prefix = ""
      status = "Enabled"

      destination {
        bucket = "${aws_s3_bucket.replica.arn}"
      }
    }
  }

  tags {
    environment = "${var.environment}"
    terraform   = true
  }
}

resource "aws_s3_bucket_policy" "bucket" {
  provider = "aws.west2"
  bucket   = "${aws_s3_bucket.bucket.id}"

  policy = <<POLICY
{
  "Version": "2008-10-17",
  "Id": "PolicyForCloudFrontPrivateContent",
  "Statement": [
      {
          "Sid": "1",
          "Effect": "Allow",
          "Principal": {
              "AWS": "${aws_cloudfront_origin_access_identity.origin_access.iam_arn}"
          },
          "Action": "s3:GetObject",
          "Resource": "arn:aws:s3:::${aws_s3_bucket.bucket.id}/*"
      }
  ]
}
POLICY
}
