output "api_gateway_url" {
  description = "Base URL for all API calls"
  value       = aws_api_gateway_stage.prod.invoke_url
}

output "live_url" {
  description = "Live application URL"
  value       = "https://${aws_cloudfront_distribution.frontend.domain_name}"
}

output "frontend_bucket" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.frontend.bucket
}

output "cloudfront_distribution_id" {
  description = "CloudFront ID"
  value       = aws_cloudfront_distribution.frontend.id
}