#################################################################
##### Defining resources for the IAM and Lambda dependencies ####
#################################################################
data "aws_caller_identity" "this" {
  provider = aws.acc
}

data "aws_partition" "this" {
  provider = aws.acc
}

data "aws_region" "this" {
  provider = aws.acc
}

locals {
  account_id = data.aws_caller_identity.this.account_id
  partition  = data.aws_partition.this.partition
  region     = data.aws_region.this.name
}

data "aws_bedrock_foundation_model" "this" {
  model_id = "anthropic.claude-3-haiku-20240307-v1:0"
}

resource "aws_iam_role" "bedrock_agent_role" {
  provider = aws.acc
  name     = "AmazonBedrockExecutionRoleForAgents_BedrockAssistant"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:${local.partition}:bedrock:${local.region}:${local.account_id}:agent/*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "bedrock_agent_policy" {
  provider = aws.acc
  name     = "AmazonBedrockAgentBedrockFoundationModelPolicy_BedrockAssistant"
  role     = aws_iam_role.bedrock_agent_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "bedrock:InvokeModel"
        Effect   = "Allow"
        Resource = data.aws_bedrock_foundation_model.this.model_arn
      }
    ]
  })
}

###############
###############
###############
data "aws_iam_policy" "lambda_basic_execution" {
  provider = aws.acc
  name     = "AWSLambdaBasicExecutionRole"
}

# Action group Lambda execution role
resource "aws_iam_role" "lambda_bedrock_api" {
  provider = aws.acc
  name     = "FunctionExecutionRoleForLambda_BedrockAPI"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = "${local.account_id}"
          }
        }
      }
    ]
  })
  managed_policy_arns = [data.aws_iam_policy.lambda_basic_execution.arn]
}


###################
###################
###################

# Action group Lambda function
data "archive_file" "bedrock_api_zip" {
  type             = "zip"
  source_file      = "${path.module}/lambda/bedrock_api/index.py"
  output_path      = "${path.module}/tmp/bedrock_api.zip"
  output_file_mode = "0666"
}

resource "aws_lambda_function" "bedrock_api" {
  provider                       = aws.acc
  function_name                  = "BedrockAPI"
  role                           = aws_iam_role.lambda_bedrock_api.arn
  description                    = "A Lambda function for the forex API action group"
  filename                       = data.archive_file.bedrock_api_zip.output_path
  handler                        = "index.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = "120"
  reserved_concurrent_executions = 100

  # source_code_hash is required to detect changes to Lambda code/zip
  source_code_hash = data.archive_file.bedrock_api_zip.output_base64sha256

  tracing_config {
    mode = "Active"
  }
  dead_letter_config {
    target_arn = aws_sqs_queue.dlq.arn
  }
}

resource "aws_lambda_permission" "bedrock_api" {
  provider       = aws.acc
  action         = "lambda:invokeFunction"
  function_name  = aws_lambda_function.bedrock_api.function_name
  principal      = "bedrock.amazonaws.com"
  source_account = local.account_id
  source_arn     = "arn:aws:bedrock:${local.region}:${local.account_id}:agent/*"
}


#################################################################
######### Defining the agent and action group resources #########
#################################################################
resource "aws_bedrockagent_agent" "bedrock_asst" {
  provider                = aws.acc
  agent_name              = "BedrockAssistant"
  agent_resource_role_arn = aws_iam_role.bedrock_agent_role.arn
  description             = "An assisant that provides forex rate information."
  foundation_model        = data.aws_bedrock_foundation_model.this.model_id
  instruction             = "You are an assistant that looks up today's currency exchange rates. A user may ask you what the currency exchange rate is for one currency to another. They may provide either the currency name or the three-letter currency code. If they give you a name, you may first need to first look up the currency code by its name."
}

resource "aws_bedrockagent_agent_action_group" "bedrock_api" {
  provider                   = aws.acc
  action_group_name          = "ForexAPI"
  agent_id                   = aws_bedrockagent_agent.bedrock_asst.id
  agent_version              = "DRAFT"
  description                = "The currency exchange rates API"
  skip_resource_in_use_check = true
  action_group_executor {
    lambda = aws_lambda_function.bedrock_api.arn
  }
  api_schema {
    payload = file("${path.module}/lambda/bedrock_api/schema.yaml")
  }
}

resource "aws_iam_role_policy" "bedrock_lambda_sqs_permissions" {
  provider = aws.acc
  name     = "${aws_iam_role.lambda_bedrock_api.name}-sqs-access-${data.aws_region.current.name}"
  role     = aws_iam_role.lambda_bedrock_api.id
  policy   = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
          "sqs:ReceiveMessage",
          "sqs:SendMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
      ],
      "Effect": "Allow",
      "Resource": [
          "arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_sqs_queue.this.name}",
          "arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_sqs_queue.dlq.name}"
      ]
    }
  ]
}
EOF
}
