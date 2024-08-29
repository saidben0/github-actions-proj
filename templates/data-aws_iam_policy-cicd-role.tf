data "aws_iam_policy_document" "gh_actions_oidc_policy" {
  statement {
    sid    = "ManageLLandManLambdaFunctions"
    effect = "Allow"
    actions = [
      "lambda:GetFunction",
      "lambda:CreateFunction",
      "lambda:TagResource",
      "lambda:GetFunctionConfiguration",
      "lambda:DeleteFunction",
      "lambda:GetFunctionCodeSigningConfig",
      "lambda:PutFunctionConcurrency",
      "lambda:ListVersionsByFunction",
      "lambda:ListTags",
      "lambda:UntagResource",
      "lambda:AddPermission",
      "lambda:GetPolicy",
      "lambda:RemovePermission",
      "lambda:Update*"
    ]
    resources = "arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:llandman-queue-processing"
  }

  statement {
    sid    = "ManageLLandManLambdaFunctionLayer"
    effect = "Allow"
    actions = [
      "lambda:GetLayerVersion",
      "lambda:PublishLayerVersion",
      "lambda:DeleteLayerVersion"
    ]
    resources = [
      "arn:aws:lambda:us-east-1:${ACCOUNT_ID}:layer:python-libs",
      "arn:aws:lambda:us-east-1:${ACCOUNT_ID}:layer:python-libs:*"
    ]
  }

  statement {
    sid    = "ManageLambdaFunctionSourceMapping"
    effect = "Allow"
    actions = [
      "lambda:GetEventSourceMapping",
      "lambda:CreateEventSourceMapping"
    ]
    resources = "*"
  }

  statement {
    sid    = "ManageLambdaFunctionSourceMapping"
    effect = "Allow"
    actions = [
      "lambda:DeleteEventSourceMapping"
    ]
    resources = "arn:aws:lambda:us-east-1:${ACCOUNT_ID}:event-source-mapping:*"
  }

  statement {
    sid    = "ManageLLandManDynamoDBTable"
    effect = "Allow"
    actions = [
      "dynamodb:DescribeTimeToLive",
      "dynamodb:DeleteTable",
      "dynamodb:DescribeTable",
      "dynamodb:CreateTable",
      "dynamodb:ListTagsOfResource",
      "dynamodb:UpdateContinuousBackups",
      "dynamodb:TagResource",
      "dynamodb:UntagResource",
      "dynamodb:DescribeContinuousBackups",
      "dynamodb:Update*"
    ]
    resources =  "arn:aws:dynamodb:us-east-1:${ACCOUNT_ID}:table/llandman-model-outputs"
  }

  statement {
    sid    = "RetriveInputBucketObjects"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketNotification",
      "s3:PutBucketNotification"
    ]
    resources =  [
      "arn:aws:s3:::enverus-courthouse-dev-chd-plants",
      "arn:aws:s3:::enverus-courthouse-dev-chd-plants/*"
    ]
  }

  statement {
    sid    = "ManageTerraformStateFile"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:GetObjectTagging",
      "s3:GetBucketObjectLockConfiguration",
      "s3:PutObjectVersionAcl",
      "s3:ListBucket",
      "s3:GetBucketNotification",
      "s3:PutBucketNotification"
    ]
    resources =  [
      "arn:aws:s3:::${TFSTATE_FILE_BUCKET}",
      "arn:aws:s3:::${TFSTATE_FILE_BUCKET}/*"
    ]
  }

  statement {
    sid    = "ManageLLandManSQSQueues"
    effect = "Allow"
    actions = [
      "sqs:UntagQueue",
      "sqs:CreateQueue",
      "sqs:TagQueue",
      "sqs:GetQueueAttributes",
      "sqs:DeleteQueue",
      "sqs:SetQueueAttributes",
      "sqs:ListQueueTags"
    ]
    resources =  [
      "arn:aws:sqs:us-east-1:${ACCOUNT_ID}:llandman-queue",
      "arn:aws:sqs:us-east-1:${ACCOUNT_ID}:llandman-dlq"
    ]
  }

  statement {
    sid    = "LLandmanBedrockPromptManagement"
    effect = "Allow"
    actions = [
      "bedrock:GetPrompt",
      "bedrock:ListTagsForResource",
      "bedrock:CreatePrompt",
      "bedrock:UpdatePrompt",
      "bedrock:ListPrompts",
      "bedrock:GetFoundationModelAvailability",
      "bedrock:ListFoundationModels",
      "bedrock:DeletePrompt"
    ]
    resources =  [
      "arn:aws:bedrock:us-east-1:${ACCOUNT_ID}:prompt/*",
      "arn:aws:bedrock:*::foundation-model/*"
    ]
  }

  statement {
    sid    = "CFNAccessForLLandmanBedrockPromptManagement"
    effect = "Allow"
    actions = [
      "cloudformation:CreateResource",
      "cloudformation:GetResource",
      "cloudformation:DeleteResource",
      "cloudformation:GetResourceRequestStatus"
    ]
    resources =  "arn:aws:cloudformation:us-east-1:${ACCOUNT_ID}:resource/*"
  }
}