
output "app_url" {
  description = "Public application URL"
  value       = "https://${aws_cloudfront_distribution.main.domain_name}"
}

output "ecr_repository_url" {
  description = "Amazon ECR repository URL"
  value       = aws_ecr_repository.app.repository_url
}

output "frontend_bucket" {
  description = "Frontend S3 bucket name"
  value       = aws_s3_bucket.frontend.bucket
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.main.id
}

output "alb_dns" {
  description = "Application Load Balancer DNS name"
  value       = aws_lb.main.dns_name
}

