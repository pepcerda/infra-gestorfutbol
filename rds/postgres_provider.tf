
terraform {
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.20"
    }
  }
}

# Provider con el usuario maestro (crear DBs y roles)
provider "postgresql" {
  host            = var.rds_endpoint
  username        = var.rds_master_user
  password        = var.rds_master_pass
  sslmode         = "require"
  connect_timeout = 15
}
