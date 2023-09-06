locals {
  name   = "rapp"
  region = "us-east-1"

  vpc_cidr = "10.0.0.0/20"
  azs      = slice(data.aws_availability_zones.available.names, 0, 2)

  tags = {
    Example    = local.name
    Project = "terraform-aws-rapp"
    product  = "rapp"
  }
}



provider "aws" {
  region = local.region
}


data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}


module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 4.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]
  

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    type = "public"
  }

  private_subnet_tags = {
    type = "private"
  }

  tags = local.tags
}


terraform {
  backend "s3" {
    bucket         = "app-r"
    key            = "vpc.tfstate"
    region         = "us-east-1" # Change to your desired AWS region
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}
