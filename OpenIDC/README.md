## OpenID Connect config

### 1- Add the identity provider into your AWS account
1- In AWS console, go to `IAM` > `Identity Providers` then click on `Add Provider`
    > For the provider URL: Use `https://token.actions.githubusercontent.com`
    > For the "Audience": Use `sts.amazonaws.com` if you are using the official action.

### 2- Add the IAM role which uses OpenID Connect `github-actions-role`
1- Attach this `Trust Relationship` to the role 
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringLike": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
                    "token.actions.githubusercontent.com:sub": "repo:saidben0/github-actions-proj:*"
                }
            }
        }
    ]
}
```

2- Add this `AdministratorAccess` policy to the role for `TESTING` purposes
    > You need to `RESTRICT` the access of this role as a best practice


## GitHub repo Workflow permissions
In your GitHub repo, make sure you grant `read and write permissions` to your github actions permissions.
  > `Settings` > Expand `Actions` on the left > `General` > Under `Workflow Permissions`, tick `Read and Write permissions`


## Use OpenID Connect in your github actions pipeline
```yaml
name: Terraform Deploy

on:
  workflow_call:
    inputs:
      aws-env:
        required: true
        type: string

permissions:
  id-token: write   # This is required for requesting the JWT
  contents: read    # This is required for actions/checkout

jobs:
  terraform:
    runs-on: ubuntu-latest
    
    steps:
      - name: Configure AWS Creds
        uses: aws-actions/configure-aws-credentials@v3
        with:
          role-to-assume: ${{ inputs.iam-role-arn }}
          aws-region: ${{ inputs.aws-region }}
          role-session-name: gh-actions-session
          role-duration-seconds: 3600
          audience: sts.amazonaws.com
      
      - name: Check Current IAM Role
        run: aws sts get-caller-identity
```

References:
  - [Configuring OpenID Connect in Amazon Web Services](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
  - 