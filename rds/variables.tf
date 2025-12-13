variable "rds_endpoint" {
  type = string
}
# ej: mydb.abcdefg.eu-west-1.rds.amazonaws.com
variable "rds_port" {
  type = number
  default = 5432
}

# Credenciales del usuario maestro de RDS (o un rol con permisos para crear DB/roles)
variable "rds_master_user" {
  type = string
}
variable "rds_master_pass" {
  type = string
  sensitive = true
}

# Datos del tenant
variable "tenant_db_name" {
  type = string
}
variable "tenant_db_user" {
  type = string
}
variable "tenant_db_pass" {
  type = string
  sensitive = true
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
# ruta al .pem en la máquina que ejecuta Terraform

# Puerto local para el túnel
variable "local_forward_port" {
  type = number
  default = 54320
}
