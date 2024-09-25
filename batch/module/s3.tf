resource "aws_s3_bucket" "batch_inference_bucket" {
  provider      = aws.acc
  bucket        = "${var.prefix}-${var.env}-batch-inference"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "this" {
  provider = aws.acc
  bucket   = aws_s3_bucket.batch_inference_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  provider = aws.acc
  bucket   = aws_s3_bucket.batch_inference_bucket.id

  rule {
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
    id     = "log"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }

    expiration {
      days = 90
    }
  }
}

resource "aws_s3_bucket_public_access_block" "batch_inference_bucket" {
  provider                = aws.acc
  bucket                  = aws_s3_bucket.batch_inference_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# resource "aws_s3_bucket_logging" "this" {
#   bucket = aws_s3_bucket.${var.inputs_bucket_name}.id

#   target_bucket = aws_s3_bucket.log_bucket.id
#   target_prefix = "log/"
# }

resource "aws_s3_bucket_ownership_controls" "this" {
  provider = aws.acc
  bucket   = aws_s3_bucket.batch_inference_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# resource "aws_s3_bucket_acl" "this" {
#   provider = aws.acc
#   bucket   = aws_s3_bucket.${var.inputs_bucket_name}.id
#   acl      = "private"

#   depends_on = [aws_s3_bucket_ownership_controls.this]
# }
########################################################################
########################################################################