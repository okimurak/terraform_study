resource "aws_instance" "web" {
  ami           = var.amis[var.region]
  instance_type = var.instance_type

  tags = {
    Name = var.name
  }
}