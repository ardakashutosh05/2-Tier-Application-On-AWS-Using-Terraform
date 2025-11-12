terraform {
  backend "s3" {
    bucket = "2-tier-terraform-state-bucket"
    key    = "backend/10weeksofcloudops-demo.tfstate"
    region = "ap-southeast-1"
    dynamodb_table = "ashu-table-lock"

  }
}
