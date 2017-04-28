resource "aws_s3_bucket" "bucket" {
  provider      = "aws.west2"
  bucket        = "${var.domain}"
  acl           = "public-read"
  force_destroy = true

  website {
    index_document = "index.html"
  }

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

  tags {
    environment = "${var.environment}"
    project     = "${var.project}"
    terraform   = true
  }
}

resource "aws_s3_bucket_policy" "bucket" {
  provider = "aws.west2"
  bucket   = "${aws_s3_bucket.bucket.id}"

  policy = <<POLICY
{
  "Version":"2012-10-17",
  "Statement":[{
	"Sid":"PublicReadGetObject",
        "Effect":"Allow",
	  "Principal": "*",
      "Action":["s3:GetObject"],
      "Resource":["${aws_s3_bucket.bucket.arn}/*"
      ]
    }
  ]
}
POLICY
}
