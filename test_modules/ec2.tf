# test module
variable "region" {}

variable "amis" {
  type = "map"
  default = {
   "ap-northeast-1" = "ami-785c491f"
   "us-east-1"      = "ami-abc123"
  }
}

resource "aws_instance" "default" {
  ami           = var.amis[var.region]
  instance_type = "t2.micro"
}

resource "aws_eip" "ip" {
  vpc      = true
  instance = aws_instance.default.id
}

output "ami" {
  value = aws_instance.default.ami
}