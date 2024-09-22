variable "prefix" {
  type    = string
  default = "llandman"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "inputs_bucket_name" {
  type    = string
  default = "enverus-courthouse-dev-chd-plants"
}

variable "lambda_function_name" {
  type    = string
  default = "queue-processing"
}

variable "lambda_role_name" {
  type    = string
  default = "llandman-dev-lambda-exec-role"
}

variable "dynamodb_table_name" {
  type    = string
  default = "model-outputs"
}

variable "kms_alias_name" {
  type    = string
  default = "key-alias"
}

variable "project_name" {
  type    = string
  default = "land-doc-processing"
}

variable "tags" {
  type = map(string)
  default = {
    GitRepo     = "Land.Llandman"
    Environment = "Dev"
    Owner       = "Ops"
  }
}

variable "python_version" {
  type = string
}

variable "prompt_ver" {
  type    = string
  default = "1"
}

variable "system_prompt_ver" {
  type    = string
  default = "1"
}

variable "security_grp_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "lambda_layer_version_arn" {
  type = string
}
