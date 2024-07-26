data "aws_caller_identity" "current" {
  provider = aws.acc
}

data "aws_region" "current" {
  provider = aws.acc
}

resource "aws_kms_key" "this" {
  provider    = aws.acc
  is_enabled  = true
  description = "Key used for sqs encryption"
  key_usage   = "ENCRYPT_DECRYPT"
  policy = templatefile("${path.module}/templates/kms_policy.json.tpl", {
    account_id = data.aws_caller_identity.current.account_id,
    aws_region = data.aws_region.current.name
  })
  enable_key_rotation = true
}

resource "aws_kms_alias" "this" {
  provider      = aws.acc
  name          = "alias/${var.kms_alias_name}"
  target_key_id = aws_kms_key.this.id
}

resource "random_id" "name" {
  byte_length = 6
  prefix      = "terraform-aws-"
}

resource "aws_sqs_queue" "dlq" {
  provider          = aws.acc
  name              = random_id.name.hex
  kms_master_key_id = aws_kms_alias.this.name
}

resource "aws_s3_bucket" "this" {
  provider      = aws.acc
  bucket        = "sfn-bucket-${random_id.name.hex}"
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "this" {
  depends_on = [aws_s3_bucket_ownership_controls.this]

  bucket = aws_s3_bucket.this.id
  acl    = "private"
}

data "archive_file" "this" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/"
  output_path = "${path.module}/output/image-extraction.zip"
}

resource "aws_lambda_function" "image_extraction_lambda_function" {
  provider                       = aws.acc
  filename                       = data.archive_file.this.output_path
  function_name                  = "image-extraction"
  role                           = aws_iam_role.image_extraction_lambda_role.arn
  handler                        = "image-extraction.lambda_handler"
  source_code_hash               = data.archive_file.this.output_base64sha256
  runtime                        = "python3.8"
  timeout                        = "120"
  reserved_concurrent_executions = 100

  tracing_config {
    mode = "Active"
  }
  dead_letter_config {
    target_arn = aws_sqs_queue.dlq.arn
  }
}

resource "aws_cloudwatch_log_group" "EnverusSFNLogGroup" {
  provider          = aws.acc
  name_prefix       = "/aws/vendedlogs/states/"
  retention_in_days = 60
}

resource "aws_sfn_state_machine" "sfn_state_machine" {
  provider   = aws.acc
  name       = var.sfn_name
  role_arn   = aws_iam_role.sfn_role.arn
  definition = file("${path.module}/templates/statemachine.asl.json")
  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.EnverusSFNLogGroup.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.image_extraction_lambda_function.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.this.arn
}


resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket      = aws_s3_bucket.this.id
  eventbridge = true

  lambda_function {
    lambda_function_arn = aws_lambda_function.image_extraction_lambda_function.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "input/"
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}


resource "aws_dynamodb_table" "images_metadata" {
  provider     = aws.acc
  name         = "ImagesMetadata"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "ImageId"

  attribute {
    name = "ImageId"
    type = "S"
  }

  tags = {
    Name        = "images-metadata-ddb-table"
    Environment = "dev"
  }
}

####################################################
########### triggering the step function ###########
# create an eventbridge role
resource "aws_iam_role" "sfn_event_role" {
  name_prefix = "sfn-event-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })

  inline_policy {
    name = "invoke-step-function"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = "states:StartExecution"
          Effect   = "Allow"
          Resource = aws_sfn_state_machine.sfn_state_machine.arn
        }
      ]
    })
  }
}

# create an event rule
resource "aws_cloudwatch_event_rule" "sfn_rule" {
  name        = "sfn-rule"
  description = "Trigger Step Function"

  event_pattern = <<EOF
{
  "source": ["aws.s3"],
  "detail-type": ["Object Created"],
  "detail": {
    "bucket": {
      "name": ["${aws_s3_bucket.this.id}"]
    },
    "object": {
      "key": [{"prefix": "input/"}]
    }
  }
}
EOF
}

# define the step function as the target for the eventbridge rule
resource "aws_cloudwatch_event_target" "sfn_target" {
  rule     = aws_cloudwatch_event_rule.sfn_rule.name
  arn      = aws_sfn_state_machine.sfn_state_machine.arn
  role_arn = aws_iam_role.sfn_event_role.arn
}
####################################################
####################################################
