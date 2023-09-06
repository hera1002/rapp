provider "aws" {
  region = "us-east-1" # Change to your desired AWS region
}
resource "aws_s3_bucket" "terraform_state" {
  bucket = "app-r"
  acl    = "private"

  versioning {
    enabled = true
  }
}

resource "aws_dynamodb_table" "terraform_lock" {
  name           = "terraform-lock"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}
