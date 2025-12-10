# SG de EC2 del cliente: solo desde ALB
resource "aws_security_group" "client_ec2" {
  name   = "secgroup-${var.client_slug}-ec2"
  vpc_id = var.vpc_id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    security_groups = [
    var.alb_sg_id]
  }
  ingress {
    from_port = 8080
    to_port   = 8080
    protocol  = "tcp"
    security_groups = [
    var.alb_sg_id]
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
    "0.0.0.0/0"]
  }
}

# IAM para pull ECR
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = [
    "sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
      "ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_role" {
  name               = "role-${var.client_slug}-ec2"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ip-${var.client_slug}-ec2"
  role = aws_iam_role.ec2_role.name
}


# Renderizar plantillas
locals {
  docker_compose_render = templatefile("${path.module}/files/docker-compose.yml.tftpl", {
    image_frontend = var.image_frontend
    image_backend  = var.image_backend
    db_host        = var.db_host
    db_name        = var.db_name
    db_user        = var.db_user
    db_pass        = var.db_pass
  })

  application_properties_render = templatefile("${path.module}/files/application.properties.tftpl", {
    db_host     = var.db_host
    db_name     = var.db_name
    db_user     = var.db_user
    db_pass     = var.db_pass
    root_domain = "jcerdardev.es"
    # o variable si prefieres
  })

  cloud_init_render = templatefile("${path.module}/cloud-init/user-data.yaml.tftpl", {
    region                         = var.region
    docker_compose_content         = local.docker_compose_render
    application_properties_content = local.application_properties_render
  })
}

# AMI Amazon Linux 2023 (necesaria para el aws_instance)
data "aws_ami" "al2023" {
  most_recent = true
  owners = [
  "amazon"]
  filter {
    name = "name"
    values = [
    "al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "client" {
  ami           = data.aws_ami.al2023.id
  instance_type = "t3.micro"
  subnet_id     = var.private_subnets[0]
  vpc_security_group_ids = [
  aws_security_group.client_ec2.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  # Cloud-init recomendado (user_data en base64)
  user_data_base64 = base64encode(local.cloud_init_render)

  tags = {
    Name = "ec2-${var.client_slug}"
  }
}

# TG FRONTEND (HTTP/80)
resource "aws_lb_target_group" "tg_frontend" {
  name        = "tg-${var.client_slug}-front"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    path     = var.frontend_health_path
    matcher  = "200"
    protocol = "HTTP"
  }
}

# TG BACKEND (HTTP/8080)
resource "aws_lb_target_group" "tg_backend" {
  name        = "tg-${var.client_slug}-back"
  port        = 8080
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    path     = var.backend_health_path
    matcher  = "200"
    protocol = "HTTP"
  }
}

# Adjuntos
resource "aws_lb_target_group_attachment" "attach_front" {
  target_group_arn = aws_lb_target_group.tg_frontend.arn
  target_id        = aws_instance.client.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "attach_back" {
  target_group_arn = aws_lb_target_group.tg_backend.arn
  target_id        = aws_instance.client.id
  port             = 8080
}

# Regla host -> FRONTEND
resource "aws_lb_listener_rule" "rule_front" {
  listener_arn = var.alb_listener_https_arn
  priority     = 100 + random_integer.rule_pri_front.result

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_frontend.arn
  }
  condition {
    host_header {
      values = [
      var.subdomain]
    }
  }
}

# Regla host+path -> BACKEND
resource "aws_lb_listener_rule" "rule_back" {
  listener_arn = var.alb_listener_https_arn
  priority     = 200 + random_integer.rule_pri_back.result

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_backend.arn
  }
  condition {
    host_header {
      values = [
      var.subdomain]
    }
  }
  condition {
    path_pattern {
      values = var.backend_paths
    }
  }
}

resource "random_integer" "rule_pri_front" {
  min = 1
  max = 500
}
resource "random_integer" "rule_pri_back" {
  min = 1
  max = 500
}

# DNS del cliente -> ALB
resource "aws_route53_record" "client_dns" {
  zone_id = var.route53_zone_id
  name    = var.subdomain
  type    = "A"
  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}
