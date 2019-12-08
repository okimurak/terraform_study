module "sandbox" {
  source   = "./modules/ec2"
  name     = "Test EC2"
  security_group_name = "Test EC2 Security Group"
}

module "dev_server" {
  source = "./modules/httpserver"
  instance_type = "t3.micro"
}

 data "aws_iam_policy_document" "allow_describe_regions" {
  statement {
    effect = "Allow"
    actions = ["ec2:DescribeRegions"] # リージョン⼀覧を取得する
    resources = ["*"]
  }
}

module "describe_regions_for_ec2" {
  source = "./modules/iam_role"
  name = "describe-regions-for-ec2"
  identifier = "ec2.amazonaws.com"
  policy = data.aws_iam_policy_document.allow_describe_regions.json
}

output "public_dns" {
  value = module.dev_server.public_dns
}