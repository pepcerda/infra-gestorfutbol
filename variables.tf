
variable "aws_region" {
  default = "eu-west-1"
}

variable "ecr_frontend_image" {
  description = "ECR image URI for frontend"
}

variable "ecr_backend_image" {
  description = "ECR image URI for backend"
}

variable "db_username" {
  default = "admin"
}

variable "db_password" {
  default = "supersecurepassword"
}
