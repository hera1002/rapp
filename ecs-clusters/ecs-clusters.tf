provider "aws" {
  region = "us-east-1" # Change to your desired AWS region
}

resource "aws_ecs_cluster" "rapp" {
  name = "rvapp"
}

resource "aws_ecs_cluster" "rapp-int" {
  name = "rvapp-int"
}

resource "aws_ecs_cluster" "rapp-dev" {
  name = "rvapp-dev"
}

terraform {
  backend "s3" {
    bucket         = "app-r"
    key            = "cluster.tfstate"
    region         = "us-east-1" # Change to your desired AWS region
    encrypt        = true
    dynamodb_table = "terraform-lock"
    workspace_key_prefix = "tf-state"
  }
}
