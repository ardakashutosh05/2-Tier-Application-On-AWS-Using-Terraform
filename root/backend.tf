terraform {
  backend "s3" {
    bucket = "2-tier-terraform-state-bucket"
    key    = "backend/10weeksofcloudops-demo.tfstate"
    region = "us-east-1"
    dynamodb_table = "remote-backend"
  }
}
