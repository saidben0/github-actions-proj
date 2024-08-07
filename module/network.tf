# Declare the data source
data "aws_availability_zones" "available" {
  provider = aws.acc
  state    = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.12.0"

  name = "docs-processing-vpc"
  cidr = "10.0.0.0/16"

  azs = data.aws_availability_zones.available.names
  # azs              = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.0.0/24"]
  public_subnets  = ["10.0.10.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_dhcp_options  = false

  map_public_ip_on_launch = true

  providers = {
    aws = aws.acc
  }
}

resource "aws_security_group" "allow_tls" {
  provider    = aws.acc
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  provider          = aws.acc
  description       = "allow_tls_ipv4"
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = module.vpc.vpc_cidr_block
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  provider          = aws.acc
  description       = "allow_all_traffic_ipv4"
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


# # Creating Security Group 
# resource "aws_security_group" "this" {
#   provider = aws.acc
#   vpc_id = module.vpc.vpc_id
#   # Inbound Rules
#   # HTTP access from anywhere
#   ingress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   # from anywhere
#   ingress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   # HTTPS access from anywhere
#   ingress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   # SSH access from anywhere
#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   # Outbound Rules
#   # Internet access to anywhere
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }
