variable "region" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "public_subnets" {
  type = list(string)
}
variable "private_subnets" {
  type = list(string)
}

variable "route53_zone_id" {
  type = string
}
variable "acm_certificate_arn" {
  type = string
}

variable "rds_endpoint" {
  type = string
}
variable "rds_master_user" {
  type = string
}
variable "rds_master_pass" {
  type = string
}

# Bastion (EC2)
variable "bastion_host" {
  type = string
}
# IP o DNS de la EC2
variable "bastion_user" {
  type = string
  default = "ec2-user"
}
variable "bastion_port" {
  type = number
  default = 22
}
variable "bastion_private_key_path" {
  type = string
}

variable "local_forward_port" {
  type = number
  default = 54320
}
