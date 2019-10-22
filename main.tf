terraform {
  backend "s3" {
    bucket = "studyed-terraform-state1"
    region = "ap-northeast-1"
    key = "terraform.tfstate"
    encrypt = true
  }
}