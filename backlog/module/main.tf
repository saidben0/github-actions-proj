data "aws_caller_identity" "this" {
  provider = aws.acc
}

data "aws_partition" "this" {
  provider = aws.acc
}

data "aws_region" "this" {
  provider = aws.acc
}


data "aws_s3_bucket" "inputs_bucket" {
  provider = aws.acc
  bucket   = var.inputs_bucket_name
}

data "aws_iam_role" "llandman_lambda_exec_role" {
  provider = aws.acc
  name     = "${var.prefix}-${var.env}-lambda-exec-role"
}

resource "random_id" "this" {
  byte_length = 6
  prefix      = "terraform-aws-"
}


resource "aws_sqs_queue" "redrive_dlq" {
  provider   = aws.acc
  name       = "${var.prefix}-backlog-redrive-dlq.fifo"
  fifo_queue = true
}


# configure backend to access state-file of realtime/dev-use1 module
data "terraform_remote_state" "realtime_dev_use1" {
  backend = "s3"
  config = {
    # bucket = "di-dev-terraform"
    bucket = "enverus-tfstates-0823" # for testing in proserve shared acc
    # key = "dev/llandman/terraform.tfstate"
    key    = "dev/use1/tfstate" # for testing in proserve shared acc
    region = "us-east-1"
  }
}

# Package the Lambda function code
data "archive_file" "this" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_functions/"
  excludes    = ["requirements.txt"]
  output_path = "${path.module}/outputs/lambda-artifacts.zip"
}


resource "aws_lambda_function" "invoke_model_lambda_function" {
  provider                       = aws.acc
  filename                       = data.archive_file.this.output_path
  function_name                  = "${var.prefix}-backlog-invoke-model"
  role                           = data.aws_iam_role.llandman_lambda_exec_role.arn
  layers                         = [data.terraform_remote_state.realtime_dev_use1.outputs.lambda_layer_arn]
  handler                        = "lambda_handler.lambda_handler"
  source_code_hash               = data.archive_file.this.output_base64sha256
  runtime                        = "python${var.python_version}"
  timeout                        = "900"
  reserved_concurrent_executions = 100
  memory_size                    = 10240

  environment {
    variables = {
      # DDB_TABLE_NAME = aws_dynamodb_table.model_outputs.name
      QUEUE_URL = aws_sqs_queue.this.url
    }
  }

  tracing_config {
    mode = "Active"
  }
}

resource "aws_lambda_function" "model_invocation_status_lambda_function" {
  provider                       = aws.acc
  filename                       = data.archive_file.this.output_path
  function_name                  = "${var.prefix}-backlog-model-invocation-status"
  role                           = data.aws_iam_role.llandman_lambda_exec_role.arn
  layers                         = [data.terraform_remote_state.realtime_dev_use1.outputs.lambda_layer_arn]
  handler                        = "lambda_handler.lambda_handler"
  source_code_hash               = data.archive_file.this.output_base64sha256
  runtime                        = "python${var.python_version}"
  timeout                        = "900"
  reserved_concurrent_executions = 100
  memory_size                    = 1024

  environment {
    variables = {
      # DDB_TABLE_NAME = aws_dynamodb_table.model_outputs.name
      QUEUE_URL = aws_sqs_queue.this.url
    }
  }

  tracing_config {
    mode = "Active"
  }
}

resource "aws_lambda_function" "model_outputs_retrieval_lambda_function" {
  provider                       = aws.acc
  filename                       = data.archive_file.this.output_path
  function_name                  = "${var.prefix}-backlog-model-outputs-retrieval"
  role                           = data.aws_iam_role.llandman_lambda_exec_role.arn
  layers                         = [data.terraform_remote_state.realtime_dev_use1.outputs.lambda_layer_arn]
  handler                        = "lambda_handler.lambda_handler"
  source_code_hash               = data.archive_file.this.output_base64sha256
  runtime                        = "python${var.python_version}"
  timeout                        = "900"
  reserved_concurrent_executions = 100
  memory_size                    = 1024

  environment {
    variables = {
      # DDB_TABLE_NAME = aws_dynamodb_table.model_outputs.name
      QUEUE_URL = aws_sqs_queue.this.url
    }
  }

  tracing_config {
    mode = "Active"
  }
}


resource "aws_sqs_queue" "this" {
  provider                    = aws.acc
  name                        = "${var.prefix}-backlog-queue.fifo"
  visibility_timeout_seconds  = 900
  delay_seconds               = 0
  max_message_size            = 10000
  message_retention_seconds   = 864000
  receive_wait_time_seconds   = 10
  fifo_queue                  = true
  content_based_deduplication = true
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.redrive_dlq.arn
    maxReceiveCount     = 4
  })
}

# Define an sqs policy to allow S3 to send messages to the SQS queue
resource "aws_sqs_queue_policy" "this" {
  provider  = aws.acc
  queue_url = aws_sqs_queue.this.url

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "s3.amazonaws.com"
        },
        Action   = "sqs:SendMessage",
        Resource = aws_sqs_queue.this.arn,
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = data.aws_s3_bucket.inputs_bucket.arn
          }
        }
      }
    ]
  })
}

# map sqs queue to trigger the lambda function when an 3 event is received
resource "aws_lambda_event_source_mapping" "this" {
  provider         = aws.acc
  event_source_arn = aws_sqs_queue.this.arn
  function_name    = aws_lambda_function.invoke_model_lambda_function.arn
  enabled          = true
  batch_size       = 1
}


# listen for "Bedrock Batch Inference Job State Change" events
resource "aws_cloudwatch_event_rule" "bedrock_batch_inference_complete" {
  provider      = aws.acc
  name          = "${var.prefix}-bedrock-batch-inference-complete"
  description   = "Trigger when AWS Bedrock batch inference job is complete"
  event_pattern = <<PATTERN
  {
    "source": ["aws.bedrock"],
    "detail-type": ["Batch Inference Job State Change"],
    "detail": {
      "batchJobName": [{
        "prefix": "${var.prefix}"
      }],
      "status": ["Completed"]
    }
  }
  PATTERN
}


resource "aws_cloudwatch_event_target" "lambda_target" {
  provider  = aws.acc
  rule      = aws_cloudwatch_event_rule.bedrock_batch_inference_complete.name
  target_id = "InvokeLambdaFunction"
  arn       = aws_lambda_function.model_outputs_retrieval_lambda_function.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  provider      = aws.acc
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.model_outputs_retrieval_lambda_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.bedrock_batch_inference_complete.arn
}
