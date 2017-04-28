data "aws_acm_certificate" "certificate" {
  provider = "aws.east1"
  domain   = "${var.certificate_domain}"
}

resource "aws_cloudfront_origin_access_identity" "origin_access" {
  comment = "access-identity-s3"
}

resource "aws_cloudfront_distribution" "distribution" {
  origin {
    domain_name = "${aws_s3_bucket.bucket.bucket_domain_name}"
    origin_id   = "${var.project}-${var.environment}"

    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.origin_access.cloudfront_access_identity_path}"
    }
  }

  origin {
    domain_name = "${aws_s3_bucket.replica.bucket_domain_name}"
    origin_id   = "${var.project}-${var.environment}-replica"

    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.origin_access.cloudfront_access_identity_path}"
    }
  }

  aliases             = ["${var.domain}"]
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${var.project}-${var.environment}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    compress = true

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = "${data.aws_acm_certificate.certificate.arn}"
    minimum_protocol_version = "TLSv1"
    ssl_support_method       = "sni-only"
  }

  tags {
    environment = "${var.environment}"
    project     = "${var.project}"
    terraform   = true
  }
}
