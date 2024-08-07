resource "aws_iam_role" "image_extraction_lambda_role" {
  provider           = aws.acc
  name               = "${var.lambda_role_name}-${data.aws_region.current.name}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "image_extraction_lambda_policy" {
  provider = aws.acc
  name     = "${var.lambda_policy_name}-${data.aws_region.current.name}"
  role     = aws_iam_role.image_extraction_lambda_role.id
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
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Encrypt*",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
      ],
      "Resource": "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_kms_alias.this.name}"
    },
    {
      "Action": [
        "logs:CreateLogGroup",     
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.image_extraction_lambda_function.function_name}:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeNetworkInterfaces",
        "ec2:CreateNetworkInterface",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeInstances",
        "ec2:AttachNetworkInterface"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

# resource "aws_iam_role_policy" "lambda_sqs_permissions" {
#   provider = aws.acc
#   name     = "${var.lambda_policy_name}-sqs-access-${data.aws_region.current.name}"
#   role     = aws_iam_role.image_extraction_lambda_role.id
#   policy   = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": [
#           "sqs:ReceiveMessage",
#           "sqs:SendMessage",
#           "sqs:DeleteMessage",
#           "sqs:GetQueueAttributes"
#       ],
#       "Effect": "Allow",
#       "Resource": [
#           "arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_sqs_queue.this.name}",
#           "arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_sqs_queue.dlq.name}"
#       ]
#     }
#   ]
# }
# EOF
# }

resource "aws_iam_role" "sfn_role" {
  provider           = aws.acc
  name               = "${var.sfn_role_name}-${data.aws_region.current.name}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "states.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "sfn_role_policy" {
  provider = aws.acc
  statement {
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [
      "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:*"
    ]
  }

  statement {
    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "logs:CreateLogDelivery",
      "logs:GetLogDelivery",
      "logs:UpdateLogDelivery",
      "logs:DeleteLogDelivery",
      "logs:ListLogDeliveries",
      "logs:PutResourcePolicy",
      "logs:DescribeResourcePolicies",
      "logs:DescribeLogGroups"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role_policy" "sfn_role_policy" {
  provider   = aws.acc
  name       = "sfn_role_policy"
  role       = aws_iam_role.sfn_role.id
  policy     = data.aws_iam_policy_document.sfn_role_policy.json
  depends_on = [aws_iam_role.sfn_role]
}


# Define an sqs policy to allow S3 to send messages to the SQS queue
resource "aws_sqs_queue_policy" "this" {
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
            "aws:SourceArn" = aws_s3_bucket.this.arn
          }
        }
      }
    ]
  })
}
