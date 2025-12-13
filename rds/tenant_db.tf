# Abre un túnel en background hacia RDS usando el bastion.



#############################################
# 0) Espera a que el túnel SSM esté listo
#############################################
resource "null_resource" "wait_for_ssm_tunnel" {
  triggers = {
    local_port = tostring(var.local_forward_port)
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]
    command = <<-EOT
      $ErrorActionPreference = "Stop"
      $LocalPort = [int]${self.triggers.local_port}
      Write-Host ("Esperando a que 127.0.0.1:{0} esté en LISTEN (máx 60s)..." -f $LocalPort)

      # Intentamos con Get-NetTCPConnection; si no existe, probamos Test-NetConnection
      $deadline = (Get-Date).AddSeconds(60)
      $ready = $false
      while ((Get-Date) -lt $deadline) {
        try {
          $conn = Get-NetTCPConnection -LocalAddress "127.0.0.1" -LocalPort $LocalPort -State Listen -ErrorAction Stop
          if ($conn) { $ready = $true; break }
        } catch {
          $ok = Test-NetConnection -ComputerName 127.0.0.1 -Port $LocalPort -InformationLevel Quiet
          if ($ok) { $ready = $true; break }
        }
        Start-Sleep -Seconds 1
      }

      if (-not $ready) {
        throw "El puerto 127.0.0.1:$LocalPort no está escuchando. Abre el túnel SSM y reintenta."
      }

      Write-Host ("Túnel detectado en 127.0.0.1:{0}" -f $LocalPort)
    EOT
  }
}



# 1) Crear base de datos del cliente
resource "postgresql_database" "tenant" {
  provider = postgresql.admin
  name = var.tenant_db_name
  depends_on = [
    null_resource.wait_for_ssm_tunnel]
}


# 2) Crear usuario (rol) del cliente con login
resource "postgresql_role" "tenant_user" {
  provider = postgresql.admin
  name = var.tenant_db_user
  login = true
  password = var.tenant_db_pass
  depends_on = [
    null_resource.wait_for_ssm_tunnel]
}


# 3) Permisos mínimos para conectar y sesiones temporales
resource "postgresql_grant" "tenant_privs_connect" {
  provider = postgresql.admin
  database = postgresql_database.tenant.name
  role = postgresql_role.tenant_user.name
  object_type = "database"
  privileges = [
    "CONNECT",
    "TEMPORARY"]
  depends_on = [
    null_resource.wait_for_ssm_tunnel]
}


# 4) Provider alias apuntando a la DB del cliente con su usuario
provider "postgresql" {
  alias = "tenant"
  host = "127.0.0.1"
  port = var.local_forward_port
  username = var.tenant_db_user
  password = var.tenant_db_pass
  database = var.tenant_db_name
  sslmode = "require"
  connect_timeout = 15
  superuser = false
}


# 5) Ejecutar tu schema.sql una única vez (provisión inicial)
#    Usa el recurso "postgresql_query" (si está disponible en tu versión del provider).

# rds/tenant_db.tf  (sustituye el postgresql_query por esto)
#Comandos para linux/macOS
#resource "null_resource" "init_schema" {
#  depends_on = [
#    null_resource.ssh_tunnel,
#    postgresql_database.tenant,
#    postgresql_role.tenant_user,
#    postgresql_grant.tenant_privs_connect
#  ]
#
#  provisioner "local-exec" {
#    interpreter = [
#      "/bin/bash",
#      "-c"]
#    command = <<-EOC
#      set -euo pipefail
#      export PGPASSWORD='${var.tenant_db_pass}'
#      export PGSSLMODE='require'
#      # Conectar por el túnel
#      psql -h 127.0.0.1 -p ${var.local_forward_port} \
#           -U ${var.tenant_db_user} \
#           -d ${var.tenant_db_name} \
#           -v "ON_ERROR_STOP=1" \
#           -f ${path.module}/init/schema.sql
#    EOC
#  }
#}


resource "null_resource" "init_schema" {
  depends_on = [
    null_resource.wait_for_ssm_tunnel,
    postgresql_database.tenant,
    postgresql_role.tenant_user,
    postgresql_grant.tenant_privs_connect,
    postgresql_grant.tenant_schema_public_create
  ]

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command = <<-EOC
      $ErrorActionPreference = "Stop"
      $env:PGPASSWORD = "${var.tenant_db_pass}"
      $env:PGSSLMODE  = "require"

      & psql `
        -h 127.0.0.1 `
        -p ${var.local_forward_port} `
        -U ${var.tenant_db_user} `
        -d ${var.tenant_db_name} `
        -v "ON_ERROR_STOP=1" `
        -f "${path.module}/init/schema.sql"
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
