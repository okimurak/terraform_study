module "terraform_state" {
  source   = "./modules/s3"
  bucket_name = "studyed-terraform-state1"
  is_versioning = true
}