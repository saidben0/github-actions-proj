data "aws_iam_policy_document" "queue-processing_lambda_policy" {
  statement {
    sid    = "ManageLLandManSQSQueues"
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:SendMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]
    resources = [
      "arn:aws:sqs:us-east-1:${var.account_id}:llandman-queue",
      "arn:aws:sqs:us-east-1:${var.account_id}:llandman-dlq"
    ]
  }

  statement {
    sid    = "RetrieveInputsBucketObjects"
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:List*",
      "s3:Describe*",
      "s3-object-lambda:Get*",
      "s3-object-lambda:List*"
    ]
    resources = [
      "arn:aws:s3:::enverus-courthouse-dev-chd-plants",
      "arn:aws:s3:::enverus-courthouse-dev-chd-plants/*"
    ]
  }

  statement {
    sid    = "ManageLLandManDynamoDBTable"
    effect = "Allow"
    actions = [
      "dynamodb:DescribeTimeToLive",
      "dynamodb:DescribeTable",
      "dynamodb:PutItem",
      "dynamodb:Update*"
    ]
    resources = "arn:aws:dynamodb:us-east-1:${var.account_id}:table/llandman-model-outputs"
  }

  statement {
    sid    = "LLandmanBedrockPromptManagement"
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel",
      "bedrock:GetPrompt",
      "bedrock:ListPrompts"
    ]
    resources = [
      "arn:aws:bedrock:us-east-1:${var.account_id}:prompt/*",
      "arn:aws:bedrock:*::foundation-model/*"
    ]
  }

  statement {
    sid    = "CreatePutCloudWatchLogsOfLlandmanLambdaFunction"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = "arn:aws:logs:us-east-1:${var.account_id}:log-group:/aws/lambda/llandman-queue-processing:*"
  }

  statement {
    sid    = "AllowLambdaFunctionToConnectToVPC"
    effect = "Allow"
    actions = [
      "ec2:DescribeNetworkInterfaces",
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeInstances",
      "ec2:AttachNetworkInterface"
    ]
    resources = "*"
  }

}