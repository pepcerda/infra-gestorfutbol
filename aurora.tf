
resource "aws_rds_cluster" "aurora" {
  cluster_identifier      = "aurora-serverless"
  engine                  = "aurora-postgresql"
  engine_version          = "15.3"
  database_name           = "appdb"
  master_username         = var.db_username
  master_password         = var.db_password
  skip_final_snapshot     = true
  storage_encrypted       = true

  scaling_configuration {
    auto_pause               = true
    min_capacity             = 2
    max_capacity             = 4
    seconds_until_auto_pause = 300
  }

  vpc_security_group_ids = [aws_security_group.ecs_sg.id]
  db_subnet_group_name   = module.vpc.database_subnet_group
}
