terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# Generate random ID for bucket uniqueness
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Main S3 bucket
resource "aws_s3_bucket" "main_bucket" {
  bucket = "${var.bucket_name_prefix}-${var.environment}-${random_id.bucket_suffix.hex}"
  
  tags = merge(var.tags, {
    Name        = "${var.bucket_name_prefix}-${var.environment}"
    Environment = var.environment
    CreatedBy   = "Terraform"
  })
}

# Conditional versioning
resource "aws_s3_bucket_versioning" "main_versioning" {
  count  = var.enable_versioning ? 1 : 0
  bucket = aws_s3_bucket.main_bucket.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "main_encryption" {
  bucket = aws_s3_bucket.main_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "main_pab" {
  bucket = aws_s3_bucket.main_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}