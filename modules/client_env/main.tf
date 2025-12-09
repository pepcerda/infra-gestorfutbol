# SG de EC2 del cliente: solo desde ALB
resource "aws_security_group" "client_ec2" {
  name = "sg-${var.client_slug}-ec2"
  vpc_id = var.vpc_id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [
      var.alb_sg_id]
  }
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    security_groups = [
      var.alb_sg_id]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
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
      ;
      identifiers = [
        "ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_role" {
  name = "role-${var.client_slug}-ec2"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  role = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ip-${var.client_slug}-ec2"
  role = aws_iam_role.ec2_role.name
}

# AMI Amazon Linux 2023
data "aws_ami" "al2023" {
  most_recent = true
  owners = [
    "amazon"]
  filter {
    name = "name"
    ;
    values = [
      "al2023-ami-*-x86_64"]
  }
}

# EC2 del cliente (docker-compose con front/back)
resource "aws_instance" "client" {
  ami = data.aws_ami.al2023.id
  instance_type = "t3.micro"
  subnet_id = var.private_subnets[0]
  vpc_security_group_ids = [
    aws_security_group.client_ec2.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y docker
    systemctl enable docker && systemctl start docker

    # Login a ECR
    aws ecr get-login-password --region ${var.region} \
      | docker login --username AWS --password-stdin 050752624219.dkr.ecr.${var.region}.amazonaws.com

    mkdir -p /opt/app && cd /opt/app
    cat > docker-compose.yml <<'YML'
    version: '3.8'
    services:
      frontend:
        image: ${var.image_frontend}
        ports: [ "80:80" ]
        restart: always
      backend:
        image: ${var.image_backend}
        environment:
          POSTGRES_URI: ${var.db_host}
          POSTGRES_DB:  ${var.db_name}
          POSTGRES_USER:${var.db_user}
          POSTGRES_PASSWORD:${var.db_pass}
        ports: [ "8080:8080" ]
        restart: always
    YML
    curl -L https://github.com/docker/compose/releases/download/v2.29.2/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    docker-compose up -d
  EOF

  tags = {
    Name = "ec2-${var.client_slug}"
  }
}

# TG FRONTEND (HTTP/80)
resource "aws_lb_target_group" "tg_frontend" {
  name = "tg-${var.client_slug}-front"
  port = 80
  protocol = "HTTP"
  target_type = "instance"
  vpc_id = var.vpc_id

  health_check {
    path = var.frontend_health_path
    matcher = "200"
    protocol = "HTTP"
  }
}

# TG BACKEND (HTTP/8080)
resource "aws_lb_target_group" "tg_backend" {
  name = "tg-${var.client_slug}-back"
  port = 8080
  protocol = "HTTP"
  target_type = "instance"
  vpc_id = var.vpc_id

  health_check {
    path = var.backend_health_path
    matcher = "200"
    protocol = "HTTP"
  }
}

# Adjuntos
resource "aws_lb_target_group_attachment" "attach_front" {
  target_group_arn = aws_lb_target_group.tg_frontend.arn
  target_id = aws_instance.client.id
  port = 80
}

resource "aws_lb_target_group_attachment" "attach_back" {
  target_group_arn = aws_lb_target_group.tg_backend.arn
  target_id = aws_instance.client.id
  port = 8080
}

# Regla host -> FRONTEND
resource "aws_lb_listener_rule" "rule_front" {
  listener_arn = var.alb_listener_https_arn
  priority = 100 + random_integer.rule_pri_front.result

  action {
    type = "forward",
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
  priority = 200 + random_integer.rule_pri_back.result

  action {
    type = "forward",
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
  name = var.subdomain
  type = "A"
  alias {
    name = var.alb_dns_name
    zone_id = var.alb_zone_id
    evaluate_target_health = true
  }
}
