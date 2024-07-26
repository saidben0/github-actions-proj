variable "region" {}

variable "lambda_role_name" {
  type    = string
  default = "image_extraction_lambda_role"
}
variable "lambda_policy_name" {
  type    = string
  default = "image_extraction_lambda_policy"
}

variable "kms_alias_name" {
  type    = string
  default = "sqs-key-alias"
}

variable "kms_alias_name2" {
  type    = string
  default = "cloudwatch-key-alias"
}

variable "vpc_cidr_block" {
  type        = string
  description = "VPC CIDR"
  default     = "10.0.0.0/16"
}


variable "subnet_private_cidr_block" {
  type        = string
  description = "Private subnet CIDR"
  default     = "10.0.8.0/21"
}

variable "sfn_name" {
  type    = string
  default = "enverus-sfn"
}

variable "sfn_role_name" {
  type    = string
  default = "enverus-sfn-role"
}