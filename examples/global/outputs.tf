output "rule_group_id" {
  description = "AWS WAF Rule Group which contains all rules for OWASP Top 10 protection."
  value       = "${module.owasp_top_10_rules.rule_group_id}"
}

output "01_sql_injection_rule_id" {
  description = "AWS WAF Rule which mitigates SQL Injection Attacks."
  value       = "${module.owasp_top_10_rules.01_sql_injection_rule_id}"
}

output "02_auth_token_rule_id" {
  description = "AWS WAF Rule which blacklists bad/hijacked JWT tokens or session IDs."
  value       = "${module.owasp_top_10_rules.02_auth_token_rule_id}"
}

output "03_xss_rule_id" {
  description = "AWS WAF Rule which mitigates Cross Site Scripting Attacks."
  value       = "${module.owasp_top_10_rules.03_xss_rule_id}"
}

output "04_paths_rule_id" {
  description = "AWS WAF Rule which mitigates Path Traversal, LFI, RFI."
  value       = "${module.owasp_top_10_rules.04_paths_rule_id}"
}

output "06_php_insecure_rule_id" {
  description = "AWS WAF Rule which mitigates PHP Specific Security Misconfigurations."
  value       = "${module.owasp_top_10_rules.06_php_insecure_rule_id}"
}

output "07_size_restriction_rule_id" {
  description = "AWS WAF Rule which mitigates abnormal requests via size restrictions."
  value       = "${module.owasp_top_10_rules.07_size_restriction_rule_id}"
}

output "08_csrf_rule_id" {
  description = "AWS WAF Rule which enforces the presence of CSRF token in request header."
  value       = "${module.owasp_top_10_rules.08_csrf_rule_id}"
}

output "09_server_side_include_rule_id" {
  description = "AWS WAF Rule which blocks request patterns for webroot objects that shouldn't be directly accessible."
  value       = "${module.owasp_top_10_rules.09_server_side_include_rule_id}"
}

output "webacl_traffic_logging_bucket_name" {
  description = "The name of the bucket which store WebACL traffic information."
  value       = "${module.webacl_supporting_resources.webacl_traffic_logging_bucket_name}"
}

output "firehose_delivery_stream_arn" {
  description = "The ARN of Kinesis Firehose which are going to be used for delivering all traffic information from WAF WebACL to S3 bucket."
  value       = "${module.webacl_supporting_resources.firehose_delivery_stream_arn}"
}

output "webacl_id" {
  description = "The ID of the WebACL."
  value       = "${aws_waf_web_acl.tsiwaf_webacl.id}"
}
