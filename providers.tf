terraform {
  required_version = ">= 1.5.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws",
      version = ">= 6.21"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql",
      version = "~> 1.20.0"
    }
  }
}

provider "aws" {
  region = var.region
  # eu-west-3
}


# Provider PostgreSQL (root): credenciales del usuario maestro para crear DBs/roles
provider "postgresql" {
  host            = var.rds_endpoint
  username        = var.rds_master_user
  password        = var.rds_master_pass
  sslmode         = "require"
  connect_timeout = 15
}

