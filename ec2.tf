resource "aws_s3_bucket" "testtest" {
  bucket = "testtesttesttest-test"
  acl    = "private"
}

resource "aws_instance" "sandbox" {
  ami           = "ami-785c491f"
  instance_type = "t2.micro"

  depends_on = [aws_s3_bucket.testtest]
}

resource "aws_eip" "ip" {
  vpc      = true
  instance = aws_instance.sandbox.id
}