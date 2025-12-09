output "tg_frontend_arn" {
  value = aws_lb_target_group.tg_frontend.arn
}
output "tg_backend_arn" {
  value = aws_lb_target_group.tg_backend.arn
}
output "client_ec2_id" {
  value = aws_instance.client.id
}
output "client_fqdn" {
  value = aws_route53_record.client_dns.fqdn
}
