variable "region" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "public_subnets" {
  type = list(string)
}
variable "route53_zone_id" {
  type = string
}
variable "acm_certificate_arn" {
  type = string
}
