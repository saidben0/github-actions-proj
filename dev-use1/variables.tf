variable "inputs_bucket_name" {
  type    = string
  default = "enverus-courthouse-dev-chd-plants-0823"
}

variable "lambda_function_name" {
  type    = string
  default = "queue-processing"
}

variable "lambda_role_name" {
  type    = string
  default = "queue-processing_lambda_role"
}

variable "lambda_policy_name" {
  type    = string
  default = "queue-processing_lambda_policy"
}

variable "dynamodb_table_name" {
  type    = string
  default = "model-outputs"
}

variable "prompt_id" {
  type    = string
  default = "3DKW6HGLLD"
}

variable "prompt_ver" {
  type    = string
  default = "3"
}

variable "system_prompt_id" {
  type    = string
  default = "IB5O7AZE0G"
}

variable "system_prompt_ver" {
  type    = string
  default = "1"
}
