resource "aws_s3_bucket" "terraform_state" {
  bucket = "studyed-terraform-state1"
  versioning {
    enabled = true
  }
}