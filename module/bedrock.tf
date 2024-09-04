resource "awscc_bedrock_prompt" "this" {
  default_variant = "variantOne"
  name            = "${var.prefix}-prompt"
  variants = [
    {
      inference_configuration = {
        text = {
          temperature = 1
          top_p       = 0.9900000095367432
          max_tokens  = 300
          # stop_sequences = ["\\n\\nHuman:"]
          top_k = 250
        }
      }

      name = "variantOne"
      template_configuration = {
        text = {
          text = file("${path.module}/prompt_template.txt")
        }
      }
      template_type = "TEXT"
    },
  ]
}
