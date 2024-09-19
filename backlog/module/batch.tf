data "aws_iam_role" "llandman_batch_exec_role" {
  provider = aws.acc
  name     = "${var.prefix}-${var.env}-batch-exec-role"
}

data "aws_security_group" "this" {
  provider = aws.acc
  id       = var.security_grp_id
}

data "aws_subnet" "this" {
  provider = aws.acc
  id       = var.subnet_id
}


# Create a Compute Environment
resource "aws_batch_compute_environment" "this" {
  provider                 = aws.acc
  compute_environment_name = "${var.prefix}-compute-environment"

  compute_resources {
    max_vcpus = 16

    security_group_ids = [
      data.aws_security_group.this.id
    ]

    subnets = [
      data.aws_subnet.this.id
    ]

    type = "FARGATE"
  }

  service_role = data.aws_iam_role.llandman_batch_exec_role.arn
  type         = "MANAGED"
}

# Create a Job Queue
resource "aws_batch_job_queue" "this" {
  provider = aws.acc
  name     = "${var.prefix}-job-queue"
  state    = "ENABLED"
  priority = 1
  compute_environment_order {
    order               = 1
    compute_environment = aws_batch_compute_environment.this.arn
  }
}

# Create a Job Definition
resource "aws_batch_job_definition" "this" {
  provider = aws.acc
  name     = "${var.prefix}-job-definition"

  type = "container"

  platform_capabilities = [
    "FARGATE",
  ]

  container_properties = jsonencode({
    command = ["echo", "test"]
    image   = "busybox"
    # jobRoleArn = "arn:aws:iam::${local.account_id}:role/AWSBatchS3ReadOnly"

    fargatePlatformConfiguration = {
      platformVersion = "LATEST"
    }

    resourceRequirements = [
      {
        type  = "VCPU"
        value = "0.25"
      },
      {
        type  = "MEMORY"
        value = "512"
      }
    ]

    executionRoleArn : data.aws_iam_role.llandman_batch_exec_role.arn
  })
}


# listen for "Bedrock Batch Inference Job State Change" events
resource "aws_cloudwatch_event_rule" "bedrock_batch_inference_complete" {
  provider = aws.acc
  name        = "${var.prefix}-bedrock_batch_inference_complete"
  description = "Trigger when AWS Bedrock batch inference job is complete"
  event_pattern = jsonencode({
    source = ["aws.bedrock"]
    detail-type = ["Bedrock Batch Inference Job State Change"]
    detail = {
      status = ["COMPLETED"],
      job_arn = ["arn:${local.partition}:bedrock:${local.region}:${local.account_id}:batch-job/${var.prefix}-*"]
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  provider = aws.acc
  rule      = aws_cloudwatch_event_rule.bedrock_batch_inference_complete.name
  target_id = "InvokeLambdaFunction"
  arn       = aws_lambda_function.model_outputs_retrieval_lambda_function.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  provider = aws.acc
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.model_outputs_retrieval_lambda_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.bedrock_batch_inference_complete.arn
}


# resource "aws_eventbridge_rule" "daily_batch_trigger" {
#   provider = aws.acc
#   name        = "${var.prefix}-daily-batch-trigger"
#   description = "Trigger an AWS Batch job every day"
#   schedule_expression = "rate(1 day)"  # Runs once every day
# }

# resource "aws_eventbridge_target" "batch_target" {
#   provider = aws.acc
#   rule      = aws_eventbridge_rule.daily_batch_trigger.name
#   target_id = "${var.prefix}-BatchJobTarget"
#   arn       = aws_batch_job_definition.this.arn
#   role_arn  = aws_iam_role.eventbridge_role.arn

#   batch_target {
#     job_definition = aws_batch_job_definition.this.arn
#     job_name      = "${var.prefix}-DailyBatchJob"  # Name for the Batch job instance
#     job_queue     = aws_batch_job_queue.this.arn  # Reference to your job queue
#   }
# }


# # Create a null resource to submit a job (optional)
# resource "null_resource" "submit_job" {
#   provisioner "local-exec" {
#     command = <<EOT
#       aws batch submit-job --job-name batch-job \
#       --job-queue ${aws_batch_job_queue.this.arn} \
#       --job-definition ${aws_batch_job_definition.this.arn}
#     EOT
#   }
# }



#############################################################
#############################################################
#############################################################
# # Create an IAM Role for AWS Batch
# resource "aws_iam_role" "batch_service_role" {
#   provider        = aws.acc
#   name = "batch_service_role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Principal = {
#           Service = "batch.amazonaws.com"
#         }
#         Effect = "Allow"
#         Sid    = ""
#       }
#     ]
#   })
# }

# # Attach the necessary policies to the role
# resource "aws_iam_role_policy_attachment" "batch_policy" {
#   provider        = aws.acc
#   role       = aws_iam_role.batch_service_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
# }