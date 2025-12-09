provider "postgresql" {
  host = var.rds_endpoint
  username = var.rds_master_user
  password = var.rds_master_pass
  sslmode = "require"
  connect_timeout = 15
}
