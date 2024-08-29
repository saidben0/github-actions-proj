resource "awscc_bedrock_prompt" "this" {
  # provider                    = aws.acc
  name        = "${var.prefix}-prompt"
  description = "${var.prefix}-prompt"
  # customer_encryption_key_arn = module.dev-use1.kms_key_arn
  default_variant = "${var.prefix}-variant"

  variants = [
    {
      name          = "${var.prefix}-variant"
      template_type = "TEXT"
      model_id      = "anthropic.claude-3-5-sonnet-20240620-v1:0"
      inference_configuration = {
        text = {
          temperature = 1
          top_p       = 0.9900000095367432
          max_tokens  = 300
          top_k       = 250
        }
      }
      template_configuration = {
        text = {
          input_variables = [
            {
              name        = "topic"
              description = "The subject or theme for the playlist"
            },
            {
              name        = "number"
              description = "The number of songs in the playlist"
            },
            {
              name        = "genre"
              description = "The genre of music for the playlist"
            }
          ]

          text = "Create a {{genre}} playlist for {{topic}} consisting of {{number}} songs."
        }
      }
    }

  ]

}
