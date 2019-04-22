data "aws_region" "this" {}

data "aws_caller_identity" "this" {}

resource "random_id" "this" {
  byte_length = "8"
}

resource "aws_s3_bucket" "webacl_traffic_information" {
  bucket = "${lower(var.service_name)}-webacl-${data.aws_region.this.name}-${data.aws_caller_identity.this.account_id}-${random_id.this.hex}"
  region = "${data.aws_region.this.name}"
  acl    = "private"

  logging {
    target_bucket = "${lower(var.s3_logging_bucket)}"
    target_prefix = "${lower(var.service_name)}-webacl-${data.aws_region.this.name}-${data.aws_caller_identity.this.account_id}-${random_id.this.hex}/"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning {
    enabled = "true"
  }

  tags {
    Name          = "${lower(var.service_name)}-webacl-${data.aws_region.this.name}-${data.aws_caller_identity.this.account_id}-${random_id.this.hex}"
    Description   = "Bucket for storing ${lower(var.service_name)} WebACL traffic information"
    ProductDomain = "${lower(var.product_domain)}"
    Service       = "${lower(var.service_name)}"
    Environment   = "${lower(var.environment)}"
    ManagedBy     = "terraform"
  }
}

data "aws_iam_policy_document" "firehose_assume_role_policy" {
  statement = {
    actions = [
      "sts:AssumeRole",
    ]

    principals = {
      type = "Service"

      identifiers = [
        "firehose.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "firehose" {
  name        = "ServiceRoleForFirehose_${lower(var.service_name)}-WebACL-${random_id.this.hex}"
  path        = "/service-role/firehose/"
  description = "Service Role for ${lower(var.service_name)}-WebACL Firehose"

  assume_role_policy    = "${data.aws_iam_policy_document.firehose_assume_role_policy.json}"
  force_detach_policies = "false"
  max_session_duration  = "43200"

  tags {
    Name          = "ServiceRoleForFirehose_${lower(var.service_name)}-WebACL-${random_id.this.hex}"
    Description   = "Service Role for ${lower(var.service_name)}-WebACL Firehose"
    ProductDomain = "${lower(var.product_domain)}"
    Service       = "${lower(var.service_name)}"
    Environment   = "${lower(var.environment)}"
    ManagedBy     = "terraform"
  }
}

data "aws_iam_policy_document" "webacl_traffic_information" {
  statement = {
    effect = "Allow"

    principals = {
      type = "AWS"

      identifiers = [
        "${aws_iam_role.firehose.arn}",
      ]
    }

    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.webacl_traffic_information.arn}",
      "${aws_s3_bucket.webacl_traffic_information.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "webacl_traffic_information" {
  bucket = "${aws_s3_bucket.webacl_traffic_information.id}"
  policy = "${data.aws_iam_policy_document.webacl_traffic_information.json}"
}

resource "aws_cloudwatch_log_group" "firehose_error_logs" {
  name              = "/aws/kinesisfirehose/aws-waf-logs-${lower(var.service_name)}-WebACL-${random_id.this.hex}"
  retention_in_days = "14"

  tags = {
    Name          = "/aws/kinesisfirehose/aws-waf-logs-${lower(var.service_name)}-WebACL-${random_id.this.hex}"
    Description   = "Log group to store data delivery error information from Firehose for ${lower(var.service_name)}-WebACL"
    ProductDomain = "${lower(var.product_domain)}"
    Service       = "${lower(var.service_name)}"
    Environment   = "${lower(var.environment)}"
    ManagedBy     = "terraform"
  }
}

resource "aws_cloudwatch_log_stream" "firehose_error_logs" {
  name           = "S3Delivery"
  log_group_name = "${aws_cloudwatch_log_group.firehose_error_logs.name}"
}

data "aws_iam_policy_document" "firehose_error_logs" {
  statement = {
    sid = "AllowWritingToLogStreams"

    actions = [
      "logs:PutLogEvents",
    ]

    effect = "Allow"

    resources = [
      "${aws_cloudwatch_log_stream.firehose_error_logs.arn}",
    ]
  }
}

resource "aws_iam_role_policy" "firehose_error_logs" {
  name = "AllowWritingToLogStreams"
  role = "${aws_iam_role.firehose.name}"

  policy = "${data.aws_iam_policy_document.firehose_error_logs.json}"
}

resource "aws_kinesis_firehose_delivery_stream" "waf" {
  name        = "aws-waf-logs-${lower(var.service_name)}-WebACL-${random_id.this.hex}"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = "${aws_iam_role.firehose.arn}"
    bucket_arn = "${aws_s3_bucket.webacl_traffic_information.arn}"

    buffer_size     = "${var.firehose_buffer_size}"
    buffer_interval = "${var.firehose_buffer_interval}"

    cloudwatch_logging_options {
      enabled         = "true"
      log_group_name  = "${aws_cloudwatch_log_group.firehose_error_logs.name}"
      log_stream_name = "${aws_cloudwatch_log_stream.firehose_error_logs.name}"
    }
  }

  tags = {
    Name          = "aws-waf-logs-${lower(var.service_name)}-WebACL-${random_id.this.hex}"
    Description   = "Firehose to deliver stream about traffic information from ${lower(var.service_name)}-WebACL to S3."
    ProductDomain = "${lower(var.product_domain)}"
    Service       = "${lower(var.service_name)}"
    Environment   = "${lower(var.environment)}"
    ManagedBy     = "terraform"
  }
}
