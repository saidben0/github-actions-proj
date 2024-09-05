resource "awscc_bedrock_prompt" "this" {
  provider        = awscc.acc
  default_variant = "variantOne"
  name            = "${var.prefix}-prompt"
  variants = [
    {
      inference_configuration = {
        text = {
          temperature    = 0
          # top_p          = 0.9900000095367432
          # max_tokens     = 300
          # top_k          = 250
        }
      }

      name = "variantOne"
      template_configuration = {
        text = {
          text = file("${path.module}/templates/prompt_template.txt")
        }
      }
      template_type = "TEXT"
    },
  ]

  tags = var.tags
}


# resource "awscc_bedrock_prompt_version" "this" {
#   provider   = awscc.acc
#   prompt_arn = awscc_bedrock_prompt.this.arn
# }
