terraform {
  backend "s3" {
    bucket         = "tf-state-backend-bbuy-infra"
    key            = "ecs-service.tfstate"
    region         = "eu-west-1" # Change to your desired AWS region
    encrypt        = true
    dynamodb_table = "terraform_state"
    workspace_key_prefix = "tf-state"
  }
}