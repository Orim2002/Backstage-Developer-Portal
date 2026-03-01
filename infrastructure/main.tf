module "vpc" {
  source = "./modules/vpc"

  environment             = var.environment
  vpc_cidr                = var.vpc_cidr
  availability_zones      = var.availability_zones
  public_subnet_cidrs     = var.public_subnet_cidrs
  private_subnet_cidrs    = var.private_subnet_cidrs
  private_db_subnet_cidrs = var.private_db_subnet_cidrs
}

module "alb" {
  source = "./modules/alb"

  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  certificate_arn = var.certificate_arn
}

module "rds" {
  source = "./modules/rds"

  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  private_db_subnet_ids = module.vpc.private_db_subnet_ids
  ecs_security_group_id = module.ecs.ecs_security_group_id
  db_username           = var.db_username
  db_password           = var.db_password
}

module "ecs" {
  source = "./modules/ecs"

  environment             = var.environment
  aws_region              = var.aws_region
  vpc_id                  = module.vpc.vpc_id
  private_app_subnet_ids  = module.vpc.private_app_subnet_ids
  alb_security_group_id   = module.alb.alb_security_group_id
  target_group_arn        = module.alb.target_group_arn
  frontend_target_group_arn = module.alb.frontend_target_group_arn
  alb_dns_name            = module.alb.alb_dns_name
  db_endpoint             = module.rds.db_endpoint
  db_username             = module.rds.db_username
  db_name                 = module.rds.db_name
  db_password_secret_arn  = var.db_password_secret_arn
  github_token_secret_arn = var.github_token_secret_arn
  auth_github_client_id_arn = var.auth_github_client_id_arn
  auth_github_client_secret_arn = var.auth_github_client_secret_arn
  backstage_base_url = var.backstage_base_url
}