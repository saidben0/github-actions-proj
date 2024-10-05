from jinja2 import Environment, FileSystemLoader
import yaml
import os

# Set up the Jinja2 environment
env = Environment(loader=FileSystemLoader('.'))

bucket = os.environ['BUCKET']
key = os.environ['KEY']
backend_region = os.environ['BACKEND_REGION']
provider_region = os.environ['PROVIDER_REGION']
alias = os.environ['ALIAS']
tfenv = os.environ['ENV']

# Load the backend template
template = env.get_template('backend.jinja')

# Define variables for substitution
tfbackend_context = {
    'tfbackend_bucket': bucket,
    'tfbackend_key': key,
    'tfbackend_region': backend_region,
}

# Render the template with the context
tfbackend_output = template.render(tfbackend_context)

# Save the rendered output to a tf file
with open('backend.tf', 'w') as f:
    f.write(tfbackend_output)

# # Optionally, load and print the rendered tf file to verify
# with open('backend.tf') as f:
#     config = yaml.safe_load(f)
#     print(yaml.dump(config, default_flow_style=False))


# Load the providers template
template = env.get_template('providers.jinja')

# Define variables for substitution
tfproviders_context = {
    'tfprovider_alias': alias,
    'tfprovider_region': provider_region,
    'env': tfenv
}

# Render the template with the context
tfproviders_output = template.render(tfproviders_context)

# Save the rendered output to a separate tf file
with open('providers.tf', 'w') as f:
    f.write(tfproviders_output)

# # Optionally, load and print the rendered tf file to verify
# with open('providers.tf') as f:
#     config = yaml.safe_load(f)
#     print(yaml.dump(config, default_flow_style=False))
