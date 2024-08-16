data "aws_caller_identity" "current" {
  provider = aws.acc
}

data "aws_region" "current" {
  provider = aws.acc
}

data "aws_s3_bucket" "inputs_bucket" {
  provider = aws.acc
  bucket = var.inputs_bucket_name
}

resource "aws_kms_key" "this" {
  provider    = aws.acc
  is_enabled  = true
  description = "Key used for sqs encryption"
  key_usage   = "ENCRYPT_DECRYPT"
  policy = templatefile("${path.module}/templates/kms_policy.json.tpl", {
    account_id           = data.aws_caller_identity.current.account_id,
    aws_region           = data.aws_region.current.name,
    lambda_iam_role_name = aws_iam_role.queue_processing_lambda_role.name
  })
  enable_key_rotation = true
}

resource "aws_kms_alias" "this" {
  provider      = aws.acc
  name          = "alias/${var.kms_alias_name}"
  target_key_id = aws_kms_key.this.id
}

resource "random_id" "this" {
  byte_length = 6
  prefix      = "terraform-aws-"
}


# ########################################################################
# ######### `Inputs` S3 Bucket config ##################################
# resource "aws_s3_bucket" "this" {
#   provider      = aws.acc
#   bucket        = "${var.prefix}-${random_id.this.hex}"
#   force_destroy = true
# }

# resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
#   provider = aws.acc
#   bucket   = aws_s3_bucket.${var.inputs_bucket_name}.id

#   rule {
#     apply_server_side_encryption_by_default {
#       kms_master_key_id = aws_kms_key.this.arn
#       sse_algorithm     = "aws:kms"
#     }
#   }
# }

# resource "aws_s3_bucket_versioning" "this" {
#   provider = aws.acc
#   bucket   = aws_s3_bucket.${var.inputs_bucket_name}.id
#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# resource "aws_s3_bucket_lifecycle_configuration" "this" {
#   provider = aws.acc
#   bucket   = aws_s3_bucket.${var.inputs_bucket_name}.id

#   rule {
#     abort_incomplete_multipart_upload {
#       days_after_initiation = 7
#     }
#     id     = "log"
#     status = "Enabled"

#     transition {
#       days          = 30
#       storage_class = "STANDARD_IA"
#     }

#     transition {
#       days          = 60
#       storage_class = "GLACIER"
#     }

#     expiration {
#       days = 90
#     }
#   }
# }

# resource "aws_s3_bucket_public_access_block" "this" {
#   provider                = aws.acc
#   bucket                  = aws_s3_bucket.${var.inputs_bucket_name}.id
#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }

# # resource "aws_s3_bucket_logging" "this" {
# #   bucket = aws_s3_bucket.${var.inputs_bucket_name}.id

# #   target_bucket = aws_s3_bucket.log_bucket.id
# #   target_prefix = "log/"
# # }

# resource "aws_s3_bucket_ownership_controls" "this" {
#   provider = aws.acc
#   bucket   = aws_s3_bucket.${var.inputs_bucket_name}.id
#   rule {
#     object_ownership = "BucketOwnerEnforced"
#   }
# }

# # resource "aws_s3_bucket_acl" "this" {
# #   provider = aws.acc
# #   bucket   = aws_s3_bucket.${var.inputs_bucket_name}.id
# #   acl      = "private"

# #   depends_on = [aws_s3_bucket_ownership_controls.this]
# # }
# ########################################################################
# ########################################################################

resource "aws_sqs_queue" "dlq" {
  provider          = aws.acc
  name              = "${var.prefix}-dlq-${random_id.this.hex}"
  kms_master_key_id = aws_kms_alias.this.name
}


data "archive_file" "this" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/"
  output_path = "${path.module}/output/queue-processing.zip"
}

resource "aws_lambda_function" "queue_processing_lambda_function" {
  provider                       = aws.acc
  filename                       = data.archive_file.this.output_path
  function_name                  = var.lambda_function_name
  role                           = aws_iam_role.queue_processing_lambda_role.arn
  handler                        = "queue_processing.lambda_handler"
  source_code_hash               = data.archive_file.this.output_base64sha256
  runtime                        = "python3.12"
  timeout                        = "120"
  reserved_concurrent_executions = 100

  tracing_config {
    mode = "Active"
  }
  dead_letter_config {
    target_arn = aws_sqs_queue.dlq.arn
  }

  # vpc_config {
  #   subnet_ids         = [module.vpc.private_subnets[0]]
  #   security_group_ids = [aws_security_group.allow_tls.id]
  # }

  depends_on = [aws_iam_role.queue_processing_lambda_role]
}


resource "aws_sqs_queue" "this" {
  provider                   = aws.acc
  name                       = "${var.prefix}-sqs-${random_id.this.hex}"
  kms_master_key_id          = aws_kms_alias.this.name
  visibility_timeout_seconds = 120
  delay_seconds              = 90
  max_message_size           = 2048
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 10
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 4
  })
}

resource "aws_s3_object" "inputs" {
  bucket = data.aws_s3_bucket.inputs_bucket.id
  # bucket = aws_s3_bucket.${var.inputs_bucket_name}.id
  key    = "inputs/dir1/dir2/"
  source = "/dev/null"
}

# send an s3 event to sqs when new s3 object is created/uploaded
resource "aws_s3_bucket_notification" "sqs_notification" {
  provider = aws.acc
  bucket   = data.aws_s3_bucket.inputs_bucket.id

  queue {
    queue_arn     = aws_sqs_queue.this.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = aws_s3_object.inputs.key
    # filter_suffix = ".pdf"
  }

  depends_on = [aws_sqs_queue_policy.this]
}

# map sqs queue to trigger the lambda function when an 3 event is received
resource "aws_lambda_event_source_mapping" "this" {
  provider         = aws.acc
  event_source_arn = aws_sqs_queue.this.arn
  function_name    = aws_lambda_function.queue_processing_lambda_function.arn
}


resource "aws_dynamodb_table" "images_metadata" {
  provider     = aws.acc
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "document_id"
  range_key    = "chunk"

  attribute {
    name = "document_id"
    type = "S"
  }

  attribute {
    name = "chunk"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.this.arn
  }
}


# ########################################################################
# ######### trigger lambda fx using S3 event notifications ###############
# resource "aws_lambda_permission" "allow_bucket" {
#   provider      = aws.acc
#   statement_id  = "AllowExecutionFromS3Bucket"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.queue_processing_lambda_function.arn
#   principal     = "s3.amazonaws.com"
#   source_arn    = aws_s3_bucket.${var.inputs_bucket_name}.arn
# }

# resource "aws_s3_bucket_notification" "lambda_notification" {
#   provider    = aws.acc
#   bucket      = aws_s3_bucket.${var.inputs_bucket_name}.id
#   eventbridge = true

#   lambda_function {
#     lambda_function_arn = aws_lambda_function.queue_processing_lambda_function.arn
#     events              = ["s3:ObjectCreated:*"]
#     filter_prefix       = aws_s3_object.inputs.key
#   }

#   depends_on = [aws_lambda_permission.allow_bucket]
# }
# ########################################################################
# ########################################################################

# create a dynamodb table using terraform


