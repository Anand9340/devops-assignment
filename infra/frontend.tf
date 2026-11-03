
# ----------------------------------------
# Private S3 Frontend Bucket
# ----------------------------------------

resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project}-frontend-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name      = "${var.project}-frontend"
    ManagedBy = "terraform"
  }
}

# ----------------------------------------
# S3 Ownership Controls
# ----------------------------------------

resource "aws_s3_bucket_ownership_controls" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# ----------------------------------------
# Block Public Access
# ----------------------------------------

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ----------------------------------------
# CloudFront Origin Access Control
# ----------------------------------------

resource "aws_cloudfront_origin_access_control" "s3" {
  name                              = "${var.project}-s3-oac"
  description                       = "CloudFront access to private S3 frontend"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ----------------------------------------
# CloudFront Origin Header Secret
# ----------------------------------------

resource "random_password" "origin_header" {
  length  = 40
  special = false
}

# ----------------------------------------
# API Paths
# ----------------------------------------

locals {
  api_paths = [
    "/notify/*",
    "/task_status/*",
    "/health*"
  ]
}

# ----------------------------------------
# CloudFront Distribution
# ----------------------------------------

resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  comment = "${var.project} frontend and API distribution"

  # S3 Frontend Origin
  origin {
    origin_id                = "s3"
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
  }

  # ALB Backend Origin
  origin {
    origin_id   = "alb"
    domain_name = aws_lb.main.dns_name

    custom_header {
      name  = "X-Origin-Verify"
      value = random_password.origin_header.result
    }

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # --------------------------------------
  # Frontend Default Cache Behavior
  # --------------------------------------

  default_cache_behavior {
    target_origin_id       = "s3"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    compress        = true
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  # --------------------------------------
  # API Cache Behaviors
  # --------------------------------------

  dynamic "ordered_cache_behavior" {
    for_each = local.api_paths

    content {
      path_pattern           = ordered_cache_behavior.value
      target_origin_id       = "alb"
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = [
        "GET",
        "HEAD",
        "OPTIONS",
        "PUT",
        "POST",
        "PATCH",
        "DELETE"
      ]

      cached_methods = ["GET", "HEAD"]

      compress = true

      # Disable caching for API requests
      cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"

      # Forward query strings and required viewer headers
      origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
    }
  }

  # --------------------------------------
  # Distribution Restrictions
  # --------------------------------------

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # --------------------------------------
  # Viewer Certificate
  # --------------------------------------

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name      = "${var.project}-cloudfront"
    ManagedBy = "terraform"
  }
}

# ----------------------------------------
# S3 Bucket Policy
# CloudFront OAC Only
# ----------------------------------------

data "aws_iam_policy_document" "frontend" {
  statement {
    sid    = "AllowCloudFrontRead"
    effect = "Allow"

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.frontend.arn}/*"
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"

      values = [
        aws_cloudfront_distribution.main.arn
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  policy = data.aws_iam_policy_document.frontend.json

  depends_on = [
    aws_s3_bucket_public_access_block.frontend,
    aws_s3_bucket_ownership_controls.frontend
  ]
}

