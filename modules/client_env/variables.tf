variable "region" {
  type = string
}
# eu-west-3
variable "client_slug" {
  type = string
}
# "clubx-prod"
variable "subdomain" {
  type = string
}
# "clubx.jcerdardev.es"
variable "vpc_id" {
  type = string
}
variable "private_subnets" {
  type = list(string)
}
variable "alb_listener_https_arn" {
  type = string
}
variable "alb_sg_id" {
  type = string
}
variable "alb_dns_name" {
  type = string
}
variable "alb_zone_id" {
  type = string
}
variable "route53_zone_id" {
  type = string
}

# Imágenes
variable "image_frontend" {
  type = string
}
variable "image_backend" {
  type = string
}

# DB del cliente
variable "db_host" {
  type = string
}
variable "db_name" {
  type = string
}
variable "db_user" {
  type = string
}
variable "db_pass" {
  type = string
}

# Health checks
variable "frontend_health_path" {
  type = string
  default = "/"
}
variable "backend_health_path" {
  type = string
  default = "/actuator/health"
}

# Paths backend
variable "backend_paths" {
  type = list(string)
  default = [
    "/gestor-futbol/api*",
    "/gestor-futbol/public*"]
}
