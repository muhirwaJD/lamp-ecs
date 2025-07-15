# Generate a timestamp-based suffix for unique bucket names
locals {
  bucket_suffix = formatdate("YYYYMMDD-hhmm", timestamp())
  account_id    = data.aws_caller_identity.current.account_id
}

# S3 Bucket for Application Assets (Primary Region)
resource "aws_s3_bucket" "primary_assets" {
  provider = aws.primary
  bucket   = "${var.app_name}-assets-primary-${local.account_id}"

  tags = {
    Name        = "${var.app_name}-assets-primary"
    Environment = var.environment
  }
}

# S3 Bucket for Application Assets (DR Region)
resource "aws_s3_bucket" "dr_assets" {
  provider = aws.dr
  bucket   = "${var.app_name}-assets-dr-${local.account_id}"

  tags = {
    Name        = "${var.app_name}-assets-dr"
    Environment = var.environment
    Purpose     = "disaster-recovery"
  }
}

# Enable versioning on primary bucket
resource "aws_s3_bucket_versioning" "primary_versioning" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary_assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable versioning on DR bucket
resource "aws_s3_bucket_versioning" "dr_versioning" {
  provider = aws.dr
  bucket   = aws_s3_bucket.dr_assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Cross-Region Replication Configuration
resource "aws_s3_bucket_replication_configuration" "primary_to_dr" {
  provider   = aws.primary
  role       = aws_iam_role.s3_replication.arn
  bucket     = aws_s3_bucket.primary_assets.id
  depends_on = [aws_s3_bucket_versioning.primary_versioning]

  rule {
    id     = "ReplicateToDR"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.dr_assets.arn
      storage_class = "STANDARD_IA"
    }
  }
}

# IAM Role for S3 Replication
resource "aws_iam_role" "s3_replication" {
  provider = aws.primary
  name     = "${var.app_name}-s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.app_name}-s3-replication-role"
    Environment = var.environment
  }
}

# IAM Policy for S3 Replication
resource "aws_iam_role_policy" "s3_replication_policy" {
  provider = aws.primary
  name     = "${var.app_name}-s3-replication-policy"
  role     = aws_iam_role.s3_replication.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl"
        ]
        Resource = "${aws_s3_bucket.primary_assets.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.primary_assets.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete"
        ]
        Resource = "${aws_s3_bucket.dr_assets.arn}/*"
      }
    ]
  })
}

# Lifecycle Configuration for Primary Bucket
resource "aws_s3_bucket_lifecycle_configuration" "primary_lifecycle" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary_assets.id

  rule {
    id     = "lifecycle_rule"
    status = "Enabled"
    
    filter {
      prefix = ""
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# Lifecycle Configuration for DR Bucket
resource "aws_s3_bucket_lifecycle_configuration" "dr_lifecycle" {
  provider = aws.dr
  bucket   = aws_s3_bucket.dr_assets.id

  rule {
    id     = "lifecycle_rule"
    status = "Enabled"
    
    filter {
      prefix = ""
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}
