# terraform-aws-waf-webacl-supporting-resources

[![Release](https://img.shields.io/github/release/traveloka/terraform-aws-waf-webacl-supporting-resources.svg)](https://github.com/traveloka/terraform-aws-waf-webacl-supporting-resources/releases)
[![Last Commit](https://img.shields.io/github/last-commit/traveloka/terraform-aws-waf-webacl-supporting-resources.svg)](https://github.com/traveloka/terraform-aws-waf-webacl-supporting-resources/commits/master)
![Open Source Love](https://badges.frapsoft.com/os/v1/open-source.png?v=103)

## Description

Terraform module to create resources needed by AWS WAF WebACL to:

* Enable logging of traffic information[[1]](https://docs.aws.amazon.com/waf/latest/developerguide/logging.html).
* Store logs in Parquet format[[2]](https://cwiki.apache.org/confluence/display/Hive/Parquet) for more optimized query using Athena[[3]](https://docs.aws.amazon.com/athena/latest/ug/columnar-storage.html).
* Provision query-ready Athena Database and Table which based on AWS Glue Data Catalog [[4]](https://docs.aws.amazon.com/athena/latest/ug/glue-athena.html).

![](https://user-images.githubusercontent.com/8977953/57536674-d776e180-736e-11e9-9573-5a06e32034aa.png)

Based on the diagram above, the resources going to be created are:

* S3 Bucket to store all traffic logs.
* Kinesis Data Firehose[[5]](https://docs.aws.amazon.com/firehose/latest/dev/what-is-this-service.html) to deliver traffic logs from WAF WebACL to the S3.
* Cloudwatch Log Group and Stream to store the Firehose delivery error information.
* AWS Glue Catalog Database and Table which store metadata/schema of the log data.
  * One function of those resources is to make it possible the conversion from JSON to Parquet.
  * The other function is to provision Amazon Athena Database and Table which is ready to use to perform queries.
* IAM Role and Permissions for the Firehose to do all those actions above.

> This module **WILL NOT CREATE** AWS WAF Rules and WebACL. 

To get a full picture on how to make use of this module together with AWS WAF WebACL and Rules, check examples:

* [WAF global: for Cloudfront](examples/global)
* [WAF regional: for ALB and API Gateway](examples/regional)

References

* [1] : https://docs.aws.amazon.com/waf/latest/developerguide/logging.html
* [2] : https://cwiki.apache.org/confluence/display/Hive/Parquet
* [3] : https://docs.aws.amazon.com/athena/latest/ug/columnar-storage.html
* [4] : https://docs.aws.amazon.com/athena/latest/ug/glue-athena.html
* [5] : https://docs.aws.amazon.com/firehose/latest/dev/what-is-this-service.html

## Table of Content

- [Description](#Description)
- [Prerequisites](#Prerequisites)
- [Dependencies](#Dependencies)
- [Terraform Versions](#Terraform%20Versions)
- [Terraform Providers](#Terraform%20Providers)
- [Getting Started](#Getting_Started)
- [Inputs](#Inputs)
- [Outputs](#Outputs)
- [Contributing](#Contributing)
- [License](#License)
- [Acknowledgments](#Acknowledgments)

## Prerequisites

In order to provision this module, it is require some information from an existing resources as input parameter, those resources are:

- S3 Bucket, input variable that require the information from this resource are, `s3_logging_bucket` 
- AWS KMS,  input variable that require the information from this resource are, `s3_kms_key_arn` 

## Dependencies

Doesn't have any dependencies to any other Terraform module

## Terraform Versions

Created and tested using Terraform version `0.11.14`

## Terraform Providers

| Name   | Version |
| ------ | ------- |
| aws    | ~> 2.49 |
| random | ~> 2.2  |

## Getting Started

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| description | The description of these resources. | `string` | n/a | yes |
| environment | The environment of these resources belong to. | `string` | n/a | yes |
| firehose\_buffer\_interval | Buffer incoming data for the specified period of time, in seconds, before delivering it to the destination. Valid value is between 60-900. Smaller value makes the logs delivered faster. Bigger value increase the chance to make the file size bigger, which are more efficient to query. | `string` | `"900"` | no |
| firehose\_buffer\_size | Buffer incoming data to the specified size, in MBs, before delivering it to the destination. Valid value is between 64-128. Recommended is 128, specifying a smaller buffer size can result in the delivery of very small S3 objects, which are less efficient to query. | `string` | `"128"` | no |
| product\_domain | The name of the product domain these resources belong to. | `string` | n/a | yes |
| s3\_kms\_key\_arn | KMS key ARN for S3 encryption | `string` | n/a | yes |
| s3\_logging\_bucket | The name of the target S3 Bucket which store Access Logs for WebACL Bucket created by this module | `string` | n/a | yes |
| service\_name | The name of the service these resources belong to. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| firehose\_delivery\_stream\_arn | The ARN of Kinesis Firehose which are going to be used for delivering all traffic information from WAF WebACL to S3 bucket. |
| webacl\_traffic\_logging\_bucket\_name | The name of the bucket which store WebACL traffic information. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Contributing

This module accepting or open for any contributions from anyone, please see the [CONTRIBUTING.md](https://github.com/traveloka/terraform-aws-waf-webacl-supporting-resources/blob/master/CONTRIBUTING.md) for more detail about how to contribute to this module.

## License

This module is under Apache License 2.0 - see the [LICENSE](https://github.com/traveloka/terraform-aws-waf-webacl-supporting-resources/blob/master/LICENSE) file for details.