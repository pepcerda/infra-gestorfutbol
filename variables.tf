variable "region" {
  type = string
  default = "eu-west-3"
}
variable "vpc_id" {
  type = string
  default = "vpc-01437ab862dda3461"
}
variable "public_subnets" {
  type = list(string)
  default = [
    "subnet-0ee40bf015ce5dcb3",
    "subnet-0cd5743eb112e3762",
    "subnet-0dcaebe54a4b34c65"
  ]
}
variable "private_subnets" {
  type = list(string)
  default = [
    "subnet-0c22f776bddef4b7c",
    "subnet-0f568138003a88c53",
    "subnet-0352d1f03019f0bc8"
  ]
}

variable "acm_certificate_arn" {
  type = string
}
# ACM en eu-west-3
variable "route53_zone_id" {
  type = string
}
# Hosted Zone ID

# RDS existente
variable "rds_endpoint" {
  type = string
  default = "database.c524y4uocmiu.eu-west-3.rds.amazonaws.com"
}
variable "rds_master_user" {
  type = string
  default = "postgres"
}
variable "rds_master_pass" {
  type = string
}
# usa Secrets Manager/SSM si prefieres
