resource "aws_iam_role" "replication" {
  name = "tf-iam-role-replication-static"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

output "replication_role.arn" {
  value = "${aws_iam_role.replication.arn}"
}

output "replication_role.id" {
  value = "${aws_iam_role.replication.id}"
}
