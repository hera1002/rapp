How to run 

terraform init
terraform apply -target=aws_s3_bucket.terraform_state -target=aws_dynamodb_table.terraform_lock
