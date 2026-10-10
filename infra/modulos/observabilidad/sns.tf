resource "aws_sns_topic" "topico_alertas" {
  name = "${var.nombreBase}-alertas"
}

resource "aws_sns_topic_subscription" "suscripcion_correo_alertas" {
  count = var.correoAlertas == "" ? 0 : 1

  topic_arn = aws_sns_topic.topico_alertas.arn
  protocol  = "email"
  endpoint  = var.correoAlertas
}