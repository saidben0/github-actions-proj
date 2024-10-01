resource "aws_lambda_function" "bedrock_inference1" {
  provider                       = aws.acc
  filename                       = data.archive_file.bedrock_inference.output_path
  function_name                  = "${var.prefix}-${var.env}-bedrock-inference1"
  role                           = data.aws_iam_role.llandman_lambda_exec_role.arn
  layers                         = [var.lambda_layer_version_arn]
  handler                        = "lambda_handler.lambda_handler"
  source_code_hash               = data.archive_file.bedrock_inference.output_base64sha256
  runtime                        = "python${var.python_version}"
  timeout                        = "900"
  reserved_concurrent_executions = 100
  memory_size                    = 10240

  environment {
    variables = {
      QUEUE_URL                    = aws_sqs_queue.this.url
      LLANDMAN_DEV_LAMBDA_ROLE_ARN = data.terraform_remote_state.realtime_dev_use1.outputs.lambda_role_arn
      BATCH_DATA_BUCKET            = aws_s3_bucket.batch_inference_bucket.id
    }
  }

  tracing_config {
    mode = "Active"
  }
}

resource "aws_lambda_function" "bedrock_inference2" {
  provider                       = aws.acc
  filename                       = data.archive_file.bedrock_inference.output_path
  function_name                  = "${var.prefix}-${var.env}-bedrock-inference2"
  role                           = data.aws_iam_role.llandman_lambda_exec_role.arn
  layers                         = [var.lambda_layer_version_arn]
  handler                        = "lambda_handler.lambda_handler"
  source_code_hash               = data.archive_file.bedrock_inference.output_base64sha256
  runtime                        = "python${var.python_version}"
  timeout                        = "900"
  reserved_concurrent_executions = 100
  memory_size                    = 10240

  environment {
    variables = {
      QUEUE_URL                    = aws_sqs_queue.this.url
      LLANDMAN_DEV_LAMBDA_ROLE_ARN = data.terraform_remote_state.realtime_dev_use1.outputs.lambda_role_arn
      BATCH_DATA_BUCKET            = aws_s3_bucket.batch_inference_bucket.id
    }
  }

  tracing_config {
    mode = "Active"
  }
}

