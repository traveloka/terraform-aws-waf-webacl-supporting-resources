# terraform-aws-waf-webacl-supporting-resources
This repository contains a module to create several resources needed by AWS WAF WebACL to:
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

*Please Note:* This module **WILL NOT CREATE** AWS WAF Rules and WebACL. 

If you are wondering what kind of rules that you should create to protect your App, you might want to take a look at [Related Modules](#related-modules) section below.

Also, to get a full picture on how to make use of this module together with AWS WAF WebACL and Rules, check [Examples](#examples) section.

References
* [1] : https://docs.aws.amazon.com/waf/latest/developerguide/logging.html
* [2] : https://cwiki.apache.org/confluence/display/Hive/Parquet
* [3] : https://docs.aws.amazon.com/athena/latest/ug/columnar-storage.html
* [4] : https://docs.aws.amazon.com/athena/latest/ug/glue-athena.html
* [5] : https://docs.aws.amazon.com/firehose/latest/dev/what-is-this-service.html

## Examples
AWS WAF is divided into two, Global and Regional resources. Read [this](https://docs.aws.amazon.com/waf/latest/APIReference/Welcome.html) to understand better. These examples provided will tell you more on how they are implemented:
* [waf global: for Cloudfront](examples/global)
* [waf regional: for ALB and API Gateway](examples/regional)

## Related Modules
* [terraform-aws-waf-owasp-top-10-rules](https://github.com/traveloka/terraform-aws-waf-owasp-top-10-rules)

## Author
[Rafi Kurnia Putra](https://github.com/rafikurnia)

## License
Apache 2 Licensed. See LICENSE for full details.