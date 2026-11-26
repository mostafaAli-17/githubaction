terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "your-terraform-state-bucket173173"
    key    = "iam-admin-role/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "allowed_users" {
  description = "List of IAM user ARNs allowed to assume the Admin role"
  type        = list(string)
  default     = []
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "admin_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "AWS"
      identifiers = length(var.allowed_users) > 0 ? [
        for user in var.allowed_users : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${user}"
      ] : ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

resource "aws_iam_role" "temp_admin_role" {
  name               = "GitOps-Admin-Role"
  assume_role_policy = data.aws_iam_policy_document.admin_trust_policy.json
}

resource "aws_iam_policy" "admin_policy" {
  name        = "GitOps-Account-Admin-Policy"
  description = "Full Administrator Access Policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "admin_attach" {
  role       = aws_iam_role.temp_admin_role.name
  policy_arn = aws_iam_policy.admin_policy.arn
}