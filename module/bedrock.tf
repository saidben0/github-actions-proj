resource "awscc_bedrock_prompt" "this" {
  for_each = local.bedrock_prompts

  provider        = awscc.acc
  default_variant = each.value.default_variant
  name            = each.value.name
  variants        = each.value.variants
}

resource "awscc_bedrock_prompt_version" "this" {
  for_each = local.bedrock_prompts

  provider   = awscc.acc
  prompt_arn = awscc_bedrock_prompt.this[each.key].arn
}

resource "null_resource" "main_prompt_version_ssm_param" {
  provisioner "local-exec" {
    command = <<EOT
      VERSION_NUM=$(aws bedrock-agent create-prompt-version --prompt-identifier ${local.prompt_id} | grep -i version | awk -F'"' '{print $4}')
      aws ssm put-parameter \
          --name "/dev/bedrock/prompts/${local.prompt_id}/versions/$(date +%Y%m%d%H%M%S)" \
          --type "String" \
          --value "$VERSION_NUM" \
          --overwrite || true
    EOT
  }

  triggers = {
    filebasesha = "${base64sha256(file("${path.module}/templates/prompt_template.txt"))}"
  }
  depends_on = [awscc_bedrock_prompt.this]
}

resource "null_resource" "system_prompt_version_ssm_param" {
  provisioner "local-exec" {
    command = <<EOT
      VERSION_NUM=$(aws bedrock-agent create-prompt-version --prompt-identifier ${local.system_prompt_id} | grep -i version | awk -F'"' '{print $4}')
      aws ssm put-parameter \
          --name "/dev/bedrock/prompts/${local.system_prompt_id}/versions/$(date +%Y%m%d%H%M%S)" \
          --type "String" \
          --value "$VERSION_NUM" \
          --overwrite || true
    EOT
  }

  triggers = {
    filebasesha = "${base64sha256(file("${path.module}/templates/system_prompt_template.txt"))}"
  }
  depends_on = [awscc_bedrock_prompt.this]
}


data "awscc_bedrock_prompt_version" "main_prompt" {
  provider = awscc.acc
  id       = awscc_bedrock_prompt_version.this["mainPrompt"].id

  depends_on = [null_resource.main_prompt_version_ssm_param]
}

data "awscc_bedrock_prompt_version" "system_prompt" {
  provider = awscc.acc
  id       = awscc_bedrock_prompt_version.this["systemPrompt"].id

  depends_on = [null_resource.system_prompt_version_ssm_param]
}






# # Create a Bedrock prompt for each entry in the map
# resource "awscc_bedrock_prompt" "this" {
#   for_each = var.bedrock_prompts

#   provider        = awscc.acc
#   default_variant = each.value.default_variant
#   name            = each.value.name
#   variants        = each.value.variants

#   tags = each.value.tags
# }

# output "bedrock_prompt_ids" {
#   value = { for p in awscc_bedrock_prompt.this : p.id => p.id }
# }

# resource "awscc_bedrock_prompt" "this" {
#   provider        = awscc.acc
#   default_variant = "variantOne"
#   name            = "${var.prefix}-prompt"
#   variants = [
#     {
#       inference_configuration = {
#         text = {
#           temperature = 0
#           # top_p          = 0.9900000095367432
#           # max_tokens     = 300
#           # top_k          = 250
#         }
#       }

#       name = "variantOne"
#       template_configuration = {
#         text = {
#           text = file("${path.module}/templates/prompt_template.txt")
#         }
#       }
#       template_type = "TEXT"
#     },
#   ]

#   tags = var.tags
# }


# resource "awscc_bedrock_prompt_version" "this" {
#   provider   = awscc.acc
#   prompt_arn = awscc_bedrock_prompt.this.arn
# }
