/*resource "aws_s3_bucket" "testtest" {
  bucket = "testtesttesttest-test"
  acl    = "private"
}*/


resource "aws_instance" "sandbox" {
  ami           = var.amis[var.region]
  instance_type = "t2.micro"

  provisioner "local-exec" {
    command = "echo ${aws_instance.sandbox.public_ip} > ip_address.txt"
  }
}

resource "aws_eip" "ip" {
  vpc      = true
  instance = aws_instance.sandbox.id
}

output "ami" {
  value = aws_instance.sandbox.ami
}