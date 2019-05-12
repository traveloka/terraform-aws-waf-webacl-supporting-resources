# Default AWS provider.
provider "aws" {
  version = "v2.9.0"         # Use latest if possible. See https://github.com/terraform-providers/terraform-provider-aws/releases
  region  = "ap-southeast-1"
}

# us-east-1 provider. Used by webacl_supporting_resources.
# If WAF resources are meant to protect Cloudfront, they should be Global Resources, and Global Resources are located in us-east-1.
provider "aws" {
  version = "v2.9.0"    # Use latest if possible. See https://github.com/terraform-providers/terraform-provider-aws/releases
  region  = "us-east-1"
  alias   = "us-east-1"
}

provider "random" {
  version = "v2.1.2" # Use latest if possible. See https://github.com/terraform-providers/terraform-provider-random/releases
}

# AWS WAF Rules for OWASP Top 10 security risks protection.
# For a better understanding of what are those parameters mean,
# please read the description of each variable in the variables.tf file:
# https://github.com/traveloka/terraform-aws-waf-owasp-top-10-rules/blob/master/variables.tf 
module "owasp_top_10_rules" {
  source  = "traveloka/waf-owasp-top-10-rules/aws"
  version = "v0.1.1"

  product_domain = "tsi"
  service_name   = "tsiwaf"
  environment    = "staging"
  description    = "OWASP Top 10 rules for tsiwaf"

  target_scope      = "global" # [IMPORTANT] this variable value should be set to global
  create_rule_group = "true"

  max_expected_uri_size          = "512"
  max_expected_query_string_size = "1024"
  max_expected_body_size         = "4096"
  max_expected_cookie_size       = "4093"

  csrf_expected_header = "x-csrf-token"
  csrf_expected_size   = "36"
}

# Random value generator for the suffix of the resources
resource "random_id" "this" {
  byte_length = "8"
}

# A rate limiter rule
# Read more:
# https://www.terraform.io/docs/providers/aws/r/waf_rate_based_rule.html
resource "aws_waf_rate_based_rule" "rate_limiter_rule" {
  name        = "tsiwaf-rate-limiter-${random_id.this.hex}"
  metric_name = "tsiwafRateLimiter${random_id.this.hex}"

  rate_key   = "IP"
  rate_limit = "2000"
}

# The module which is defined on this repository
# For a better understanding of what are those parameters mean,
# please read the description of each variable in the variables.tf file:
# https://github.com/traveloka/terraform-aws-waf-webacl-supporting-resources/blob/master/variables.tf 
module "webacl_supporting_resources" {
  # This module is published on the registry: https://registry.terraform.io/modules/traveloka/waf-webacl-supporting-resources

  # Open the link above to see what the latest version is. Highly encouraged to use the latest version if possible.

  source  = "traveloka/waf-webacl-supporting-resources/aws"
  version = "0.2.0"

  # [IMPORTANT]
  # Pass the us-east-1 provider like this.
  # This will make all resources created by this module are on us-east-1 region.
  providers {
    aws = "aws.us-east-1"
  }

  product_domain = "tsi"
  service_name   = "tsiwaf"
  environment    = "staging"
  description    = "WebACL for tsiwaf"

  s3_logging_bucket = "<name-of-the-bucket>" # Logging bucket should be in the same region as the bucket

  firehose_buffer_size     = "128"
  firehose_buffer_interval = "60"
}

# Read more of what are those parameters mean:
# https://www.terraform.io/docs/providers/aws/r/waf_web_acl.html
resource "aws_waf_web_acl" "tsiwaf_webacl" {
  # The name or description of the web ACL.
  name = "tsiwaf-WebACL-${random_id.this.hex}"

  # The name or description for the Amazon CloudWatch metric of this web ACL.
  metric_name = "tsiwafWebACL${random_id.this.hex}"

  # Configuration block to enable WAF logging.
  logging_configuration {
    # Amazon Resource Name (ARN) of Kinesis Firehose Delivery Stream
    log_destination = "${module.webacl_supporting_resources.firehose_delivery_stream_arn}"
  }

  # Configuration block with action that you want AWS WAF to take 
  # when a request doesn't match the criteria in any of the rules 
  # that are associated with the web ACL.
  default_action {
    # Valid values are `ALLOW` and `BLOCK`.
    type = "ALLOW"
  }

  # Configuration blocks containing rules to associate with the web ACL and the settings for each rule.
  rules {
    # Specifies the order in which the rules in a WebACL are evaluated.
    # Rules with a lower value are evaluated before rules with a higher value.
    priority = "0"

    # ID of the associated WAF rule
    rule_id = "${module.owasp_top_10_rules.rule_group_id}"

    # Valid values are `GROUP`, `RATE_BASED`, and `REGULAR`
    # The rule type, either REGULAR, as defined by Rule, 
    # RATE_BASED, as defined by RateBasedRule, 
    # or GROUP, as defined by RuleGroup. 
    type = "GROUP"

    # Only used if type is `GROUP`.
    # Override the action that a group requests CloudFront or AWS WAF takes 
    # when a web request matches the conditions in the rule. 
    override_action {
      # Valid values are `NONE` and `COUNT`
      type = "NONE"
    }
  }

  rules {
    priority = "1"
    rule_id  = "${aws_waf_rate_based_rule.rate_limiter_rule.id}"
    type     = "RATE_BASED"

    # Only used if type is NOT `GROUP`.
    # The action that CloudFront or AWS WAF takes 
    # when a web request matches the conditions in the rule.
    action {
      # Valid values are `ALLOW`, `BLOCK`, and `COUNT`.
      type = "BLOCK"
    }
  }
}

# What you need to do next is modify your cloudfront to use a WebACL

