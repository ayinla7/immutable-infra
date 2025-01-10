provider "aws" {
  region = "us-west-2"
}

module "efs_module" {
  source = "../modules/efs"
  vpc_id     = "vpc-0de14e8fbcbe9410a"
  subnet_ids = ["subnet-01033882bf86e7175", "subnet-092ed6b2f720c5e76", "subnet-0c8eebfe7f34ddd9e"]
}