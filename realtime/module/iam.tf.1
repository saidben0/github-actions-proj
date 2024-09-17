resource "aws_iam_role" "queue_processing_lambda_role" {
  provider           = aws.acc
  name               = "${var.prefix}-${var.lambda_role_name}-${local.region}"
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

resource "aws_iam_role_policy" "queue_processing_lambda_policy" {
  provider = aws.acc
  name     = "${var.prefix}-${var.lambda_policy_name}-${local.region}"
  role     = aws_iam_role.queue_processing_lambda_role.id
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
          "arn:${local.partition}:sqs:${local.region}:${local.account_id}:${aws_sqs_queue.this.name}",
          "arn:${local.partition}:sqs:${local.region}:${local.account_id}:${aws_sqs_queue.dlq.name}"
      ]
    },
    {
        "Effect": "Allow",
        "Action": [
            "s3:Get*",
            "s3:List*",
            "s3:Describe*",
            "s3-object-lambda:Get*",
            "s3-object-lambda:List*"
        ],
        "Resource": [
            "arn:${local.partition}:s3:::${var.inputs_bucket_name}",
            "arn:${local.partition}:s3:::${var.inputs_bucket_name}/*"
        ]
    },
    {
			"Action": [
                "dynamodb:DescribeTimeToLive",
                "dynamodb:DescribeTable",
                "dynamodb:PutItem",
                "dynamodb:Update*"
			],
			"Effect": "Allow",
			"Resource": "arn:${local.partition}:dynamodb:${local.region}:${local.account_id}:table/${var.prefix}-${var.dynamodb_table_name}"
		},
    {
        "Effect": "Allow",
        "Action": [
		        "bedrock:InvokeModel",
            "bedrock:GetPrompt",
            "bedrock:ListPrompts"
        ],
        "Resource": [
            "arn:${local.partition}:bedrock:${local.region}:${local.account_id}:prompt/*",
            "arn:${local.partition}:bedrock:*::foundation-model/*"
        ]
    },
    {
      "Action": [
        "logs:CreateLogGroup",     
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "arn:${local.partition}:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/${aws_lambda_function.queue_processing_lambda_function.function_name}:*"
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

resource "aws_iam_role_policy" "lambda_sqs_permissions" {
  provider = aws.acc
  name     = "${var.prefix}-${var.lambda_policy_name}-sqs-access-${local.region}"
  role     = aws_iam_role.queue_processing_lambda_role.id
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
          "arn:${local.partition}:sqs:${local.region}:${local.account_id}:${aws_sqs_queue.this.name}",
          "arn:${local.partition}:sqs:${local.region}:${local.account_id}:${aws_sqs_queue.dlq.name}"
      ]
    }
  ]
}
EOF
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
            # "aws:SourceArn" = aws_s3_bucket.this.arn
            "aws:SourceArn" = data.aws_s3_bucket.inputs_bucket.arn
          }
        }
      }
    ]
  })
}
