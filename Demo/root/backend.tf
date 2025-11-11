terraform {
    backend "s3" {
        bucket = "2-tier-terraform-state-bucket"
        key    = "2-tier/terraform.tfstate"
        region = "ap-southeast-1"
        daynamodb_table = "terraform-lock-table"
    }
}