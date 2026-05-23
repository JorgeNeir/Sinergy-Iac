terraform {
  backend "s3" {
    bucket         = "terraform-state-sinergy"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}