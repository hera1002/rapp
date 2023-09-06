provider "aws" {
  region = "us-east-1" # Change to your desired AWS region
}

resource "aws_ecs_cluster" "rapp" {
  name = "rapp"
}

resource "aws_ecs_cluster" "rapp-int" {
  name = "rapp-int"
}

resource "aws_ecs_cluster" "rapp-dev" {
  name = "rapp-dev"
}

terraform {
  backend "s3" {
    bucket         = "app-r"
    key            = "cluster.tfstate"
    region         = "us-east-1" # Change to your desired AWS region
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}
