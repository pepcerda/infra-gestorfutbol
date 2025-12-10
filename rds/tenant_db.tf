
# 1) Crear base de datos del cliente
resource "postgresql_database" "tenant" {
  name = var.tenant_db_name
}

# 2) Crear usuario (rol) del cliente con login
resource "postgresql_role" "tenant_user" {
  name     = var.tenant_db_user
  login    = true
  password = var.tenant_db_pass
}

# 3) Permisos mínimos para conectar y sesiones temporales
resource "postgresql_grant" "tenant_privs_connect" {
  database    = postgresql_database.tenant.name
  role        = postgresql_role.tenant_user.name
  object_type = "database"
  privileges = [
    "CONNECT",
  "TEMPORARY"]
}

# 4) Provider alias apuntando a la DB del cliente con su usuario
provider "postgresql" {
  alias           = "tenant"
  host            = var.rds_endpoint
  username        = var.tenant_db_user
  password        = var.tenant_db_pass
  database        = var.tenant_db_name
  sslmode         = "require"
  connect_timeout = 15
}

# 5) Ejecutar tu schema.sql una única vez (provisión inicial)
#    Usa el recurso "postgresql_query" (si está disponible en tu versión del provider).

# rds/tenant_db.tf  (sustituye el postgresql_query por esto)
resource "null_resource" "init_schema" {
  depends_on = [
    postgresql_database.tenant,
    postgresql_role.tenant_user,
    postgresql_grant.tenant_privs_connect
  ]

  provisioner "local-exec" {
    command = <<EOC
      export PGPASSWORD='${var.tenant_db_pass}';
      psql -h ${var.rds_endpoint} -U ${var.tenant_db_user} \
           -d ${var.tenant_db_name} -v "ON_ERROR_STOP=1" \
           -f ${path.module}/init/schema.sql
    EOC
  }
}

output "db_name" {
  value = postgresql_database.tenant.name
}
output "db_user" {
  value = postgresql_role.tenant_user.name
}
output "db_pass" {
  value = var.tenant_db_pass
}
