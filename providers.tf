terraform {
  required_version = ">= 1.5.7"
  required_providers {
    aws = {
      source = "hashicorp/aws",
      version = ">= 6.21"
    }
    postgresql = {
      source = "cyrilgdn/postgresql",
      version = "~> 1.20.0"
    }
  }
}

provider "aws" {
  region = var.region
  # eu-west-3
}
