
terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

data "aws_caller_identity" "current" {}

# --------------------------------------------------
# Variables
# --------------------------------------------------

variable "github_repo" {
  description = "GitHub owner/repository"
  type        = string
}

# --------------------------------------------------
# Terraform Remote State Bucket
# --------------------------------------------------

resource "aws_s3_bucket" "tfstate" {
  bucket = "notifier-tfstate-${data.aws_caller_identity.current.account_id}"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect    = "Deny"
      Principal = "*"

      Action = [
        "s3:*"
      ]

      Resource = [
        aws_s3_bucket.tfstate.arn,
        "${aws_s3_bucket.tfstate.arn}/*"
      ]

      Condition = {
        Bool = {
          "aws:SecureTransport" = "false"
        }
      }
    }]
  })
}

# --------------------------------------------------
# GitHub Actions OIDC Provider
# --------------------------------------------------

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

# --------------------------------------------------
# GitHub OIDC Trust Policy
# --------------------------------------------------

data "aws_iam_policy_document" "trust" {
  statement {
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    principals {
      type = "Federated"

      identifiers = [
        aws_iam_openid_connect_provider.github.arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"

      values = [
        "repo:Anand9340@199924066/devops-assignment@1444070381:ref:refs/heads/main"
      ]
    }
  }
}

# --------------------------------------------------
# GitHub Deployment IAM Role
# --------------------------------------------------

resource "aws_iam_role" "deploy" {
  name               = "notifier-github-deploy"
  assume_role_policy = data.aws_iam_policy_document.trust.json

  max_session_duration = 3600
}

# --------------------------------------------------
# AWS Infrastructure Deployment Permissions
# --------------------------------------------------

resource "aws_iam_role_policy_attachment" "deploy_power_user" {
  role       = aws_iam_role.deploy.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# --------------------------------------------------
# IAM Permissions for ECS Task Roles
# --------------------------------------------------

resource "aws_iam_role_policy" "deploy_iam" {
  name = "notifier-github-deploy-iam"
  role = aws_iam_role.deploy.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ManageNotifierTaskRoles"
        Effect = "Allow"

        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:UpdateRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:ListRoleTags",
          "iam:PutRolePolicy",
          "iam:GetRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:ListRolePolicies",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:PassRole"
        ]

        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/notifier-*"
        ]
      },
      {
        Sid    = "ReadIAMInformation"
        Effect = "Allow"

        Action = [
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListPolicies",
          "iam:ListRoles"
        ]

        Resource = "*"
      },
      {
        Sid    = "CreateRequiredServiceLinkedRoles"
        Effect = "Allow"

        Action = [
          "iam:CreateServiceLinkedRole"
        ]

        Resource = "*"

        Condition = {
          StringEquals = {
            "iam:AWSServiceName" = [
              "ecs.amazonaws.com",
              "elasticache.amazonaws.com",
              "elasticloadbalancing.amazonaws.com"
            ]
          }
        }
      }
    ]
  })
}

# --------------------------------------------------
# Outputs
# --------------------------------------------------

output "state_bucket" {
  description = "Terraform remote state bucket"
  value       = aws_s3_bucket.tfstate.bucket
}

output "deploy_role_arn" {
  description = "GitHub Actions deployment role ARN"
  value       = aws_iam_role.deploy.arn
}

output "github_oidc_provider_arn" {
  description = "GitHub Actions OIDC provider ARN"
  value       = aws_iam_openid_connect_provider.github.arn
}
