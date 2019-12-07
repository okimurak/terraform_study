module "sandbox" {
  source   = "./modules/ec2"
  name     = "Test EC2"
  security_group_name = "Test EC2 Security Group"
}