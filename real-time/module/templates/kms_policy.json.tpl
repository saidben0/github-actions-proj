{
    "Version": "2012-10-17",
    "Id": "key-default-1",
    "Statement": [
        {
          "Sid": "Enable IAM User Permissions",
          "Effect": "Allow",
          "Principal": {
              "AWS": "arn:${partition}:iam::${account_id}:root"
          },
          "Action": "kms:*",
          "Resource": "*"
        },
        {
          "Sid": "Enable Lambda Role",
          "Effect": "Allow",
          "Principal": {
              "AWS": "arn:${partition}:iam::${account_id}:role/${lambda_iam_role_name}"
          },
          "Action": [
            "kms:Decrypt",
            "kms:GenerateDataKey*"
          ],
          "Resource": "*"
        },
        {
          "Sid": "Allow S3",
          "Effect": "Allow",
          "Principal": {
            "Service": "s3.amazonaws.com"
          },
          "Action": [
            "kms:GenerateDataKey",
            "kms:Decrypt"
          ],
          "Resource": "*"
        },
        {
          "Sid": "Allow_SQS",
          "Effect": "Allow",
          "Principal": {
            "Service": [
              "sqs.amazonaws.com"
            ]
          },
          "Action": [
            "kms:Decrypt",
            "kms:GenerateDataKey*"
          ],
          "Resource": "*"
        },
        {
          "Sid": "Allow_logs",
          "Effect": "Allow",
          "Principal": {
            "Service": [
              "logs.${region}.amazonaws.com",
              "vpc-flow-logs.amazonaws.com"
            ]
          },
          "Action": [
            "kms:Encrypt*",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:Describe*"
          ],
          "Resource": "*"
        }          
    ]
}
