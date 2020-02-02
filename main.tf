provider "aws" {
  version = "~> 2.0"
  region  = "ap-northeast-1"
}

terraform {
  backend "s3" {
    bucket = "studyed-terraform-state2"
    region = "ap-northeast-1"
    key = "study/terraform.tfstate"
    encrypt = true
  }
}

provider "github" {
  organization = "okimurak"
}