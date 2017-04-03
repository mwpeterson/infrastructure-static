resource "aws_route53_record" "s3" {
  zone_id = "${data.aws_route53_zone.domain.zone_id}"
  name    = "${var.domain}"
  type    = "A"

  alias {
    name                   = "${aws_s3_bucket.bucket.website_domain}"
    zone_id                = "${aws_s3_bucket.bucket.hosted_zone_id}"
    evaluate_target_health = true
  }
}
