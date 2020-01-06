
provider "aws" {
  region  = "${var.region}"
  shared_credentials_file = "${var.shared_cred_file}"
  profile = "${var.cred_profile}"
}

module "networking" {
  source               = "./modules/networking"
  environment          = "${var.environment}"
  vpc_cidr             = "10.0.0.0/16"
  public_subnets_cidr  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets_cidr = ["10.0.10.0/24", "10.0.20.0/24"]
  availability_zones   = ["${var.az1}", "${var.az2}"]
}

