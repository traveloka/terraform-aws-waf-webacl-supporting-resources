output "webacl_traffic_logging_bucket_name" {
  description = "The name of the bucket which store WebACL traffic information."
  value       = "${aws_s3_bucket.webacl_traffic_information.id}"
}

output "firehose_delivery_stream_arn" {
  description = "The ARN of Kinesis Firehose which are going to be used for delivering all traffic information from WAF WebACL to S3 bucket."
  value       = "${aws_kinesis_firehose_delivery_stream.waf.arn}"
}
