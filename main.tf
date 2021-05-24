# Get the region where the resources will be created.
data "aws_region" "this" {
}

# Get caller identity.
data "aws_caller_identity" "this" {
}

# Random generator which going to be used as name suffix for all resources.
resource "random_id" "this" {
  byte_length = "8"
}

# S3 Bucket to store WebACL Traffic Logs. This resource is needed by Amazon Kinesis Firehose as data delivery output target.
resource "aws_s3_bucket" "webacl_traffic_information" {
  bucket = "${lower(var.service_name)}-webacl-${data.aws_region.this.name}-${data.aws_caller_identity.this.account_id}-${random_id.this.hex}"
  region = data.aws_region.this.name
  acl    = "private"

  logging {
    target_bucket = lower(var.s3_logging_bucket)
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

  tags = {
    Name          = "${lower(var.service_name)}-webacl-${data.aws_region.this.name}-${data.aws_caller_identity.this.account_id}-${random_id.this.hex}"
    Description   = "Bucket for storing ${lower(var.service_name)} WebACL traffic information"
    ProductDomain = lower(var.product_domain)
    Service       = lower(var.service_name)
    Environment   = lower(var.environment)
    ManagedBy     = "terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.webacl_traffic_information.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# AWS Glue Catalog Database. This resource is needed by Amazon Kinesis Firehose as data format conversion configuration, for transforming from JSON to Parquet.
resource "aws_glue_catalog_database" "database" {
  name        = "${lower(var.service_name)}_webacl_${random_id.this.hex}"
  description = "Glue Catalog Database for ${lower(var.service_name)} WAF Logs"
}

# This table store column information that is needed by Amazon Kinesis Firehose as data format conversion configuration, for transforming from JSON to Parquet.
resource "aws_glue_catalog_table" "table" {
  name          = "logs"
  database_name = aws_glue_catalog_database.database.name

  description = "Table which stores schema of WAF Logs for ${lower(var.service_name)} WebACL"

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL       = "TRUE"
    classification = "Parquet"
  }

  partition_keys {
    name = "year"
    type = "int"
  }
  partition_keys {
    name = "month"
    type = "int"
  }
  partition_keys {
    name = "day"
    type = "int"
  }
  partition_keys {
    name = "hour"
    type = "int"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.webacl_traffic_information.id}/logs"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      name                  = "ParquetHiveSerDe"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
    }

    columns {
      name = "timestamp"
      type = "timestamp"
    }
    columns {
      name = "formatversion"
      type = "int"
    }
    columns {
      name = "webaclid"
      type = "string"
    }
    columns {
      name = "terminatingruleid"
      type = "string"
    }
    columns {
      name = "terminatingruletype"
      type = "string"
    }
    columns {
      name = "action"
      type = "string"
    }
    columns {
      name = "httpsourcename"
      type = "string"
    }
    columns {
      name = "httpsourceid"
      type = "string"
    }
    columns {
      name = "rulegrouplist"
      type = "array<struct<ruleGroupId:string,terminatingRule:string,nonTerminatingMatchingRules:array<struct<action:string,ruleId:string>>,excludedRules:array<struct<exclusionType:string,ruleId:string>>>>"
    }
    columns {
      name = "ratebasedrulelist"
      type = "array<struct<rateBasedRuleId:string,limitKey:string,maxRateAllowed:int>>"
    }
    columns {
      name = "nonterminatingmatchingrules"
      type = "array<struct<action:string,ruleId:string>>"
    }
    columns {
      name = "httprequest"
      type = "struct<clientIp:string,country:string,headers:array<struct<name:string,value:string>>,uri:string,args:string,httpVersion:string,httpMethod:string,requestId:string>"
    }
  }
}

# This log group is needed by Amazon Kinesis Firehose for storing delivery error information.
resource "aws_cloudwatch_log_group" "firehose_error_logs" {
  name              = "/aws/kinesisfirehose/aws-waf-logs-${lower(var.service_name)}-WebACL-${random_id.this.hex}"
  retention_in_days = "14"

  tags = {
    Name          = "/aws/kinesisfirehose/aws-waf-logs-${lower(var.service_name)}-WebACL-${random_id.this.hex}"
    Description   = "Log group to store data delivery error information from Firehose for ${lower(var.service_name)}-WebACL"
    ProductDomain = lower(var.product_domain)
    Service       = lower(var.service_name)
    Environment   = lower(var.environment)
    ManagedBy     = "terraform"
  }
}

# This log stream is the one which hold the information inside the log group above.
resource "aws_cloudwatch_log_stream" "firehose_error_logs" {
  name           = "S3Delivery"
  log_group_name = aws_cloudwatch_log_group.firehose_error_logs.name
}

# Policy document that will allow the Firehose to assume an IAM Role.
data "aws_iam_policy_document" "firehose_assume_role_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"

      identifiers = [
        "firehose.amazonaws.com",
      ]
    }
  }
}

# IAM Role for the Firehose, so it able to access those resources above.
resource "aws_iam_role" "firehose" {
  name        = "ServiceRoleForFirehose_${lower(var.service_name)}-WebACL-${random_id.this.hex}"
  path        = "/service-role/firehose/"
  description = "Service Role for ${lower(var.service_name)}-WebACL Firehose"

  assume_role_policy    = data.aws_iam_policy_document.firehose_assume_role_policy.json
  force_detach_policies = "false"
  max_session_duration  = "43200"

  tags = {
    Name          = "ServiceRoleForFirehose_${lower(var.service_name)}-WebACL-${random_id.this.hex}"
    Description   = "Service Role for ${lower(var.service_name)}-WebACL Firehose"
    ProductDomain = lower(var.product_domain)
    Service       = lower(var.service_name)
    Environment   = lower(var.environment)
    ManagedBy     = "terraform"
  }
}

# Policy document that will be attached to the S3 Bucket, to make the bucket accessible by the Firehose.
data "aws_iam_policy_document" "allow_s3_actions" {
  statement {
    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = [
        aws_iam_role.firehose.arn,
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
      aws_s3_bucket.webacl_traffic_information.arn,
      "${aws_s3_bucket.webacl_traffic_information.arn}/*",
    ]
  }
}

# Attach the policy above to the bucket.
resource "aws_s3_bucket_policy" "webacl_traffic_information" {
  bucket = aws_s3_bucket.webacl_traffic_information.id
  policy = data.aws_iam_policy_document.allow_s3_actions.json
}

# Policy document that will be attached to the IAM Role, to make the role able to put logs to Cloudwatch.
data "aws_iam_policy_document" "allow_put_log_events" {
  statement {
    sid = "AllowWritingToLogStreams"

    actions = [
      "logs:PutLogEvents",
    ]

    effect = "Allow"

    resources = [
      aws_cloudwatch_log_stream.firehose_error_logs.arn,
    ]
  }
}

# Attach the policy above to the IAM Role.
resource "aws_iam_role_policy" "allow_put_log_events" {
  name = "AllowWritingToLogStreams"
  role = aws_iam_role.firehose.name

  policy = data.aws_iam_policy_document.allow_put_log_events.json
}

# Policy document that will be attached to the IAM Role, to make the role able to get Glue Table Versions.
data "aws_iam_policy_document" "allow_glue_get_table_versions" {
  statement {
    sid = "AllowGettingGlueTableVersions"

    actions = [
      "glue:GetTableVersions",
    ]

    effect = "Allow"

    resources = [
      "arn:aws:glue:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:table/${aws_glue_catalog_database.database.name}/logs",
      "arn:aws:glue:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:database/${aws_glue_catalog_database.database.name}",
      "arn:aws:glue:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:catalog",
    ]
  }
}

# Attach the policy above to the IAM Role.
resource "aws_iam_role_policy" "allow_glue_get_table_versions" {
  name = "AllowGettingGlueTableVersions"
  role = aws_iam_role.firehose.name

  policy = data.aws_iam_policy_document.allow_glue_get_table_versions.json
}

# Creating the Firehose.
resource "aws_kinesis_firehose_delivery_stream" "waf" {
  name        = "aws-waf-logs-${lower(var.service_name)}-WebACL-${random_id.this.hex}"
  destination = "extended_s3"

  extended_s3_configuration {
    # Ensure encrytped delivery stream - https://www.cloudconformity.com/knowledge-base/aws/Firehose/delivery-stream-encrypted.html
    kms_key_arn = var.s3_kms_key_arn

    role_arn   = aws_iam_role.firehose.arn
    bucket_arn = aws_s3_bucket.webacl_traffic_information.arn

    buffer_size     = var.firehose_buffer_size
    buffer_interval = var.firehose_buffer_interval

    prefix              = "logs/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
    error_output_prefix = "errors/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/!{firehose:error-output-type}"

    cloudwatch_logging_options {
      enabled         = "true"
      log_group_name  = aws_cloudwatch_log_group.firehose_error_logs.name
      log_stream_name = aws_cloudwatch_log_stream.firehose_error_logs.name
    }

    data_format_conversion_configuration {
      enabled = "true"

      input_format_configuration {
        deserializer {
          open_x_json_ser_de {
          }
        }
      }

      output_format_configuration {
        serializer {
          parquet_ser_de {
          }
        }
      }

      schema_configuration {
        role_arn      = aws_iam_role.firehose.arn
        database_name = aws_glue_catalog_table.table.database_name
        table_name    = aws_glue_catalog_table.table.name
        region        = data.aws_region.this.name
      }
    }
  }

  tags = {
    Name          = "aws-waf-logs-${lower(var.service_name)}-WebACL-${random_id.this.hex}"
    Description   = "Firehose to deliver stream about traffic information from ${lower(var.service_name)}-WebACL to S3."
    ProductDomain = lower(var.product_domain)
    Service       = lower(var.service_name)
    Environment   = lower(var.environment)
    ManagedBy     = "terraform"
  }
}

