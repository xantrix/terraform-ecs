provider "aws" {
  region                  = var.region
  shared_credentials_file = var.shared_cred_file
  profile                 = var.cred_profile
}

module "networking" {
  source               = "./modules/networking"
  environment          = var.environment
  vpc_cidr             = "10.0.0.0/16"
  public_subnets_cidr  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets_cidr = ["10.0.10.0/24", "10.0.20.0/24"]
  availability_zones   = [var.az1, var.az2]
}

module "ecs_cluster" {
  source      = "./modules/ecs_cluster"
  environment = var.environment

  #cert_domain       = "*.domain.com"
  #ssl_policy        = "ELBSecurityPolicy-FS-2018-06"
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = flatten(module.networking.public_subnets_ids)
  security_groups_ids = flatten([
    module.networking.security_groups_ids,
  ])
  #additional sg_ids e.g. "${module.rds.db_access_sg_id}"
}

module "app" {
  source                = "./modules/ecs"
  environment           = var.environment
  name                  = "nginx"
  task_template         = "app.json"
  appname               = "nginx-test-application"
  port                  = "80"
  region                = var.region
  alb_dns_name          = module.ecs_cluster.alb_dns_name
  alb_listener_http_arn = module.ecs_cluster.alb_listener_http_arn
  alb_rule_priority     = "10"
  cpu                   = "512"
  memory                = "1024"
  desired_count         = 2
  autoscale_max         = 4
  vpc_id                = module.networking.vpc_id
  availability_zones    = [var.az1, var.az2]
  private_subnets_ids   = flatten(module.networking.private_subnets_ids)
  security_groups_ids = [
    module.networking.default_sg_id,
  ]
  #additional sg_ids e.g. "${module.rds.db_access_sg_id}"

  image                   = "nginx"
  image_tag               = "latest"
  cluster_id              = module.ecs_cluster.cluster_id
  cluster_name            = module.ecs_cluster.cluster_name
  execution_role_arn      = module.ecs_cluster.ecs_execution_role_arn
  task_role_arn           = module.ecs_cluster.ecs_execution_role_arn
  ecs_autoscale_role_arn  = module.ecs_cluster.ecs_autoscale_role_arn
  topic_logs_watchers_arn = module.ecs_cluster.topic_logs_watchers_arn

  tg_depends_on = [module.ecs_cluster.alb_listener_http_arn]
}

