# (Opcional) apex
resource "aws_route53_record" "apex_alias" {
  zone_id = var.route53_zone_id
  name    = "jcerdardev.es"
  type    = "A"
  alias {
    name                   = aws_lb.shared.dns_name
    zone_id                = aws_lb.shared.zone_id
    evaluate_target_health = true
  }
}
