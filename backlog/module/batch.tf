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
    # image: "your-docker-image-uri",  # Replace with your Docker image
    image : "public.ecr.aws/docker/library/alpine:latest"
    vcpus : 1,
    memory : 1024,
    command : ["echo", "Hello from AWS Batch!"],
    executionRoleArn : data.aws_iam_role.llandman_batch_exec_role.arn
    # executionRoleArn: aws_iam_role.batch_service_role.arn
  })
}

# Create a null resource to submit a job (optional)
resource "null_resource" "submit_job" {
  provisioner "local-exec" {
    command = <<EOT
      aws batch submit-job --job-name batch-job \
      --job-queue ${aws_batch_job_queue.this.arn} \
      --job-definition ${aws_batch_job_definition.this.arn}
    EOT
  }
}







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