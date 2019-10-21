variable "region" {}

variable "amis" {
  type = "map"
}

provider "aws" {
  version = "~> 2.0"
  region  = var.region
}