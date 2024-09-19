locals {
  account_id = data.aws_caller_identity.this.account_id
  partition  = data.aws_partition.this.partition
  region     = data.aws_region.this.name

  # prompt_id        = awscc_bedrock_prompt.this["mainPrompt"].prompt_id
  # system_prompt_id = awscc_bedrock_prompt.this["systemPrompt"].prompt_id
  # bedrock_prompts = {
  #   "mainPrompt" = {
  #     default_variant = "variantOne"
  #     name            = "backlog-mainPrompt"
  #     variants = [
  #       {
  #         inference_configuration = {
  #           text = {
  #             temperature = 0
  #             top_p       = 0.9000000000000000
  #             max_tokens  = 300
  #             top_k       = 250
  #           }
  #         }
  #         name = "variantOne"
  #         template_configuration = {
  #           text = {
  #             text = file("${path.module}/templates/prompt_template.txt")
  #           }
  #         }
  #         template_type = "TEXT"
  #       }
  #     ]
  #   }
  #   "systemPrompt" = {
  #     default_variant = "variantOne"
  #     name            = "backlog-systemPrompt"
  #     variants = [
  #       {
  #         inference_configuration = {
  #           text = {
  #             temperature = 0
  #             top_p       = 0.9000000000000000
  #             max_tokens  = 300
  #             top_k       = 250
  #           }
  #         }
  #         name = "variantOne"
  #         template_configuration = {
  #           text = {
  #             text = file("${path.module}/templates/system_prompt_template.txt")
  #           }
  #         }
  #         template_type = "TEXT"
  #       }
  #     ]
  #   }
  # }
}
