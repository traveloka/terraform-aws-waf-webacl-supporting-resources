variable "product_domain" {
  type        = "string"
  description = "The name of the product domain these resources belong to."
}

variable "service_name" {
  type        = "string"
  description = "The name of the service these resources belong to."
}

variable "environment" {
  type        = "string"
  description = "The environment of these resources belong to."
}

variable "description" {
  type        = "string"
  description = "The description of these resources."
}

variable "s3_logging_bucket" {
  type        = "string"
  description = "The name of an S3 Bucket which store logging for WebACL traffic information bucket. NOTE: SHOULD BE IN THE SAME REGION AS THE BUCKET."
}

variable "firehose_buffer_size" {
  type        = "string"
  description = "Buffer incoming data to the specified size, in MBs, before delivering it to the destination. The default value is 5. We recommend setting SizeInMBs to a value greater than the amount of data you typically ingest into the delivery stream in 10 seconds. For example, if you typically ingest data at 1 MB/sec set SizeInMBs to be 10 MB or higher."
  default     = "5"
}

variable "firehose_buffer_interval" {
  type        = "string"
  description = "Buffer incoming data for the specified period of time, in seconds, before delivering it to the destination. The default value is 300."
  default     = "300"
}
