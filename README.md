# terraform-aws-waf-webacl-supporting-resources
A module to create several resources needed by AWS WAF WebACL.

This will only create resources needed for WebACL to be fully functional, like:
* S3 Bucket to store all traffic logs
* Kinesis Firehose to deliver traffic logs from WAF to the S3
* IAM Service Role for the Firehose
* Cloudwatch Log Group and Stream to store the Firehose delivery error information

To create common WAF rules you can see [Related Modules](#related-modules) section.

And to find examples about how to create a full solution of WAF, check [Examples](#examples) section.

## Examples
* [waf global: for Cloudfront](examples/global)
* [waf regional: for ALB and API Gateway](examples/regional)

## Related Modules
* [terraform-aws-waf-owasp-top-10-rules](https://github.com/traveloka/terraform-aws-waf-owasp-top-10-rules)

## Author
[Rafi Kurnia Putra](https://github.com/rafikurnia)

## License
Apache 2 Licensed. See LICENSE for full details.