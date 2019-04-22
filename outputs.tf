output "webacl_traffic_logging_bucket_name" {
  description = "The name of the bucket which store WebACL traffic information."
  value       = "${element(concat(aws_s3_bucket.webacl_traffic_information.*.id, list("")), "0")}"
}

output "firehose_delivery_stream_arn" {
  description = "The ARN of Kinesis Firehose which are going to be used for delivering all traffic information from WAF WebACL to S3 bucket."
  value       = "${element(concat(aws_kinesis_firehose_delivery_stream.waf.*.arn, list("")), "0")}"
}

# In case you are wondering why there are so many ugly interpolation: 
# https://github.com/hashicorp/terraform/issues/16726

