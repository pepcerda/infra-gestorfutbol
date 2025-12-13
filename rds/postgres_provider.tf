terraform {
  required_providers {
    postgresql = {
      source = "cyrilgdn/postgresql"
      version = "~> 1.23"
      # o la que uses
    }
  }
}

# Conexión "admin" para crear DB y roles
provider "postgresql" {
  alias = "admin"
  host = "127.0.0.1"
  port = var.local_forward_port
  username = var.rds_master_user
  password = var.rds_master_pass
  database = "postgres"
  sslmode = "require"
  connect_timeout = 15
  superuser = false
}


# Conceder permisos en el esquema public para que el usuario pueda crear tablas
resource "postgresql_grant" "tenant_schema_public_create" {
  provider = postgresql.admin
  database = postgresql_database.tenant.name
  schema = "public"
  role = postgresql_role.tenant_user.name
  object_type = "schema"
  privileges = [
    "USAGE",
    "CREATE"]

  depends_on = [
    null_resource.wait_for_ssm_tunnel,
    postgresql_database.tenant,
    postgresql_role.tenant_user
  ]

}

