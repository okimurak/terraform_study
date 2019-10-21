variable "region" {
  default = "ap-northeast-1"
}

provider "aws" {
  version = "~> 2.0"
  region  = var.region
}