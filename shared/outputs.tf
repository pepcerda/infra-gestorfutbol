output "alb_listener_https_arn" {
  value = aws_lb_listener.https.arn
}
output "alb_sg_id" {
  value = aws_security_group.alb.id
}
output "alb_dns_name" {
  value = aws_lb.shared.dns_name
}
output "alb_zone_id" {
  value = aws_lb.shared.zone_id
}
