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

#https://docs.aws.amazon.com/AmazonS3/latest/user-guide/server-access-logging.html
variable "s3_logging_bucket" {
  type        = "string"
  description = "The name of the target S3 Bucket which store Access Logs for WebACL Bucket created by this module"
}

variable "s3_kms_key_arn" {
  type        = "string"
  description = "KMS key ARN for S3 encryption"
}

variable "firehose_buffer_size" {
  type        = "string"
  description = "Buffer incoming data to the specified size, in MBs, before delivering it to the destination. Valid value is between 64-128. Recommended is 128, specifying a smaller buffer size can result in the delivery of very small S3 objects, which are less efficient to query."
  default     = "128"
}

variable "firehose_buffer_interval" {
  type        = "string"
  description = "Buffer incoming data for the specified period of time, in seconds, before delivering it to the destination. Valid value is between 60-900. Smaller value makes the logs delivered faster. Bigger value increase the chance to make the file size bigger, which are more efficient to query."
  default     = "900"
}
