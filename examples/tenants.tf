
module "shared" {
  source              = "../shared"
  region              = var.region
  acm_certificate_arn = var.acm_certificate_arn
  route53_zone_id     = var.route53_zone_id
  vpc_id              = var.vpc_id
  public_subnets      = var.public_subnets
}

# --- DB trial ---
module "db_trial" {
  source = "../rds"

  rds_endpoint    = var.rds_endpoint
  rds_master_user = var.rds_master_user
  rds_master_pass = var.rds_master_pass

  tenant_db_name = "clubx_trial"
  tenant_db_user = "clubx_trial_user"
  tenant_db_pass = "admin"

  bastion_host = var.bastion_host
  bastion_private_key_path = var.bastion_private_key_path
  bastion_user = var.bastion_user
  bastion_port = var.bastion_port
  local_forward_port = var.local_forward_port

}


# --- Cliente trial ---
module "client_trial" {
  source      = "../modules/client_env"
  region      = var.region
  client_slug = "clubx-trial"
  subdomain   = "clubx-trial.jcerdardev.es"

  vpc_id          = var.vpc_id
  private_subnets = var.private_subnets

  alb_listener_https_arn = module.shared.alb_listener_https_arn
  alb_sg_id              = module.shared.alb_sg_id
  alb_dns_name           = module.shared.alb_dns_name
  alb_zone_id            = module.shared.alb_zone_id
  route53_zone_id        = var.route53_zone_id

  image_frontend = "050752624219.dkr.ecr.eu-west-3.amazonaws.com/jcerdar/gestorfutbol-frontend:latest"
  image_backend  = "050752624219.dkr.ecr.eu-west-3.amazonaws.com/jcerdar/gestorfutbol-backend:latest"

  db_host = var.rds_endpoint
  db_name = module.db_trial.db_name
  db_user = module.db_trial.db_user
  db_pass = module.db_trial.db_pass

  frontend_health_path = "/"
  backend_health_path  = "/actuator/health"
  backend_paths = [
    "/gestor-futbol/api*",
  "/gestor-futbol/public*"]
}

# --- DB producción ---
module "db_prod" {
  source = "../rds"

  # Variables de RDS (vienen del root: saas-infra/variables.tf + terraform.tfvars)
  rds_endpoint    = var.rds_endpoint
  rds_master_user = var.rds_master_user
  rds_master_pass = var.rds_master_pass

  # Variables del cliente
  tenant_db_name = "clubx_prod"
  tenant_db_user = "clubx_prod_user"
  tenant_db_pass = "CAMBIA_PROD_PASSWORD"

  bastion_host = var.bastion_host
  bastion_private_key_path = var.bastion_private_key_path
  bastion_user = var.bastion_user
  bastion_port = var.bastion_port
  local_forward_port = var.local_forward_port

}


# --- Cliente producción ---
module "client_prod" {
  source      = "../modules/client_env"
  region      = var.region
  client_slug = "clubx-prod"
  subdomain   = "clubx.jcerdardev.es"

  vpc_id          = var.vpc_id
  private_subnets = var.private_subnets

  alb_listener_https_arn = module.shared.alb_listener_https_arn
  alb_sg_id              = module.shared.alb_sg_id
  alb_dns_name           = module.shared.alb_dns_name
  alb_zone_id            = module.shared.alb_zone_id
  route53_zone_id        = var.route53_zone_id

  image_frontend = "050752624219.dkr.ecr.eu-west-3.amazonaws.com/jcerdar/gestorfutbol-frontend:latest"
  image_backend  = "050752624219.dkr.ecr.eu-west-3.amazonaws.com/jcerdar/gestorfutbol-backend:latest"

  db_host = var.rds_endpoint
  db_name = module.db_prod.db_name
  db_user = module.db_prod.db_user
  db_pass = module.db_prod.db_pass

  frontend_health_path = "/"
  backend_health_path  = "/actuator/health"
  backend_paths = [
    "/gestor-futbol/api*",
  "/gestor-futbol/public*"]
}
