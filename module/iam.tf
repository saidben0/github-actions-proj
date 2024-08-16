resource "aws_iam_role" "queue_processing_lambda_role" {
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

resource "aws_iam_role_policy" "queue_processing_lambda_policy" {
  provider = aws.acc
  name     = "${var.lambda_policy_name}-${data.aws_region.current.name}"
  role     = aws_iam_role.queue_processing_lambda_role.id
  policy   = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:Encrypt*",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
      ],
      "Resource": "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${data.aws_kms_alias.this.name}"
    },
    {
      "Action": [
        "logs:CreateLogGroup",     
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.queue_processing_lambda_function.function_name}:*"
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
  name     = "${var.lambda_policy_name}-sqs-access-${data.aws_region.current.name}"
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
          "arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_sqs_queue.this.name}",
          "arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_sqs_queue.dlq.name}"
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
