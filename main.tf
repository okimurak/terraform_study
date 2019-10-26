provider "aws" {
  version = "~> 2.0"
  region  = "ap-northeast-1"
}

terraform {
  backend "s3" {
    bucket = "studyed-terraform-state1"
    region = "ap-northeast-1"
    key = "terraform.tfstate"
    encrypt = true
  }
}