data "aws_acm_certificate" "pinkimpact" {
  provider = "aws.east1"
  domain   = "pinkimpact.com"
}

resource "aws_cloudfront_origin_access_identity" "origin_access" {
  comment = "access-identity-s3"
}

resource "aws_cloudfront_distribution" "pinkimpact" {
  origin {
    domain_name = "${aws_s3_bucket.bucket.bucket_domain_name}"
    origin_id   = "${var.repo}-${var.env}"
    origin_path = "${data.aws_acm_certificate.pinkimpact.domain}"

    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.origin_access.cloudfront_access_identity_path}"
    }
  }

  origin {
    domain_name = "${aws_s3_bucket.replica.bucket_domain_name}"
    origin_id   = "${var.repo}-${var.env}-replica"
    origin_path = "${data.aws_acm_certificate.pinkimpact.domain}"

    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.origin_access.cloudfront_access_identity_path}"
    }
  }

  aliases             = ["s3-dev.pinkimpact.com"]
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${var.repo}-${var.env}"

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

  tags {
    env       = "${var.env}"
    terraform = true
  }

  viewer_certificate {
    acm_certificate_arn      = "${data.aws_acm_certificate.pinkimpact.arn}"
    minimum_protocol_version = "TLSv1"
    ssl_support_method       = "sni-only"
  }
}
