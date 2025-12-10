
# Despliegue SaaS – Infraestructura Automatizada con Terraform (AWS)

Este proyecto automatiza el despliegue de **entornos SaaS por cliente** en AWS:

- **ALB compartido** (TLS con ACM, host & path-based routing)  
- **RDS PostgreSQL** compartida (una *base por cliente*)  
- **EC2 por cliente** (subred privada), con **cloud-init** que escribe `docker-compose.yml` y `application.properties`  
- **Route 53** (registros A *alias* por subdominio de cliente)  
- **Provisioning básico de la DB** por cliente ejecutando `schema.sql`  

> **Objetivo:** crear **trial** y **producción** para cada cliente, con el mínimo coste y una puesta en marcha consistente.

---

## ✅ 1. Prerrequisitos

Terraform >= 1.5.7  
Cuenta AWS con permisos: EC2, ELBv2, Route 53, RDS, IAM, ECR  
Dominio en Route 53 (Hosted Zone)  
Certificado ACM en la misma región del ALB (ej. *.jcerdardev.es)  
Conectividad del runner Terraform a RDS (para ejecutar schema.sql)  


## ✅ 2. Estructura del proyecto  
saas-infra/  
├─ providers.tf  
├─ variables.tf  
├─ terraform.tfvars                 # valores específicos  
├─ shared/                          # ALB + DNS  
│  ├─ alb.tf  
│  ├─ route53.tf  
│  └─ outputs.tf  
├─ rds/                             # DB + seed inicial  
│  ├─ postgresql_provider.tf  
│  ├─ tenant_db.tf  
│  └─ init/schema.sql               # << tu SQL inicial  
├─ modules/  
│  └─ client_env/                   # EC2 + TG + reglas ALB + DNS  
│     ├─ main.tf  
│     ├─ variables.tf  
│     ├─ files/docker-compose.yml.tftpl  
│     ├─ files/application.properties.tftpl  
│     └─ cloud-init/user-data.yaml.tftpl  
└─ examples/tenants.tf              # instanciación trial/prod  


## ✅ 3. Variables obligatorias (terraform.tfvars)
Terraform  
region             = "eu-west-3"
vpc_id             = "vpc-01437ab862dda3461"  
public_subnets  = [  "subnet-0ee40bf015ce5dcb3",  "subnet-0cd5743eb112e3762",  "subnet-0dcaebe54a4b34c65"]  
private_subnets = [  "subnet-0c22f776bddef4b7c",  "subnet-0f568138003a88c53",  "subnet-0352d1f03019f0bc8"]  
route53_zone_id     = "Z016845015D77Y8ISBK1Q"  
acm_certificate_arn = "arn:aws:acm:eu-west-3:050752624219:certificate/48ce6f03-78f5-4a3a-9c3f-916c959542ea"  
rds_endpoint     = "database.c524y4uocmiu.eu-west-3.rds.amazonaws.com"rds_master_user  = "postgres"  
rds_master_pass  = "CAMBIA_ESTA_PASSWORD_SEGURA"  


## ✅ 4. Comandos para desplegar
Inicializar  
<code>terraform init  
terraform validate  
terraform plan </code>  
###Despliegue por fases (recomendado)  
Fase 1 — Infraestructura compartida (ALB + DNS)  
<code>terraform apply --target module.shared </code>  
Fase 2 — Base de datos trial  
<code> terraform apply --target module.db_trial </code>  
Fase 3 — Entorno trial (EC2 + TG + reglas ALB + DNS)  
<code> terraform apply --target module.client_trial </code>  
Fase 4 — Base de datos producción  
<code> terraform apply --target module.db_prod  </code>  
Fase 5 — Entorno producción  
<code> terraform apply --target module.client_prod  </code>  

También puedes hacer terraform apply sin -target para todo, pero por fases es más seguro.


## ✅ 5. Verificación

ALB: listener 443 con reglas:

Host → TG frontend
Host + path (/gestor-futbol/api*, /gestor-futbol/public*) → TG backend


Target Groups: estado healthy (HTTP 200 en / y /actuator/health)
DNS: dig clienteX.jcerdardev.es apunta al ALB
Acceso: https://clienteX.jcerdardev.es


##✅ 6. Alta de nuevo cliente

Añade en examples/tenants.tf:

<code>
module 
"db_nuevo" {  source          = "../rds"  
tenant_db_name  = "clienteY_prod"  
tenant_db_user  = "clienteY_prod_user"  
tenant_db_pass  = "CAMBIA_PASSWORD"}

module "client_nuevo" {  
source                 = "../modules/client_env"  
region                 = var.region  
client_slug            = "clienteY-prod"  
subdomain              = "clienteY.jcerdardev.es"  
vpc_id                 = var.vpc_id  
private_subnets        = var.private_subnets  
alb_listener_https_arn = module.shared.alb_listener_https_arn  
alb_sg_id              = module.shared.alb_sg_id  
alb_dns_name           = module.shared.alb_dns_name  
alb_zone_id            = module.shared.alb_zone_id  
route53_zone_id        = var.route53_zone_id  
image_frontend         = "050752624219.dkr.ecr.eu-west-3.amazonaws.com/jcerdar/gestorfutbol-frontend:latest"  
image_backend          = "050752624219.dkr.ecr.eu-west-3.amazonaws.com/jcerdar/gestorfutbol-backend:latest"  
db_host                = var.rds_endpoint  
db_name                = module.db_nuevo.db_name  
db_user                = module.db_nuevo.db_user  
db_pass                = module.db_nuevo.db_pass
}
</code>

Ejecuta:

<code> terraform apply -target=module.db_nuevo   
terraform apply -target=module.client_nuevo </code>

##✅ 7. Troubleshooting

TG unhealthy: revisa SG, paths, contenedores (docker ps).
Certificado: ACM debe estar en eu-west-3 y cubrir el host.
DB seed: schema.sql debe ser idempotente (IF NOT EXISTS).
Cambios en plantillas: EC2 no re-ejecuta cloud-init automáticamente → reprovisiona o usa SSM.


##✅ 8. Seguridad

Usa SSM/Secrets Manager para db_pass.
IAM mínimo: ECR pull, opcional S3/SSM.
SG: EC2 solo accesible desde SG del ALB en puertos 80/8080.


##✅ 9. Destrucción
<code>terraform destroy</code>  
O por módulo:  
<code> terraform destroy --target module.client_trial</code>
<code> terraform destroy --target module.db_trial </code>
