
resource "aws_ecs_cluster" "app_cluster" {
  name = "on-demand-cluster"
}

resource "aws_security_group" "ecs_sg" {
  name        = "ecs-sg"
  description = "Allow HTTP"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_ecs_task_definition" "app_task" {
  family                   = "on-demand-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"


container_definitions = jsonencode([
  {
    name      = "frontend"
    image     = var.ecr_frontend_image
    essential = true
    portMappings = [
      {
        containerPort = 80
        protocol      = "tcp"
      }
    ]
  },
  {
    name      = "backend"
    image     = var.ecr_backend_image
    essential = true
    portMappings = [
      {
        containerPort = 8080
        protocol      = "tcp"
      }
    ]
  }
])

}
