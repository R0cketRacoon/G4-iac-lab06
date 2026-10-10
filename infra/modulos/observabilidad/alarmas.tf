resource "aws_cloudwatch_metric_alarm" "alarma_mensajes_dlq" {
  alarm_name          = "${var.nombreBase}-dlq-messages-alarm"
  alarm_description   = "Hay imagenes que no se pudieron procesar despues de 3 intentos. Revisar la DLQ y los logs de la Lambda de recorte."
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = var.nombreColaFallidos
  }

  alarm_actions = [aws_sns_topic.topico_alertas.arn]
  ok_actions    = [aws_sns_topic.topico_alertas.arn]
}

resource "aws_cloudwatch_metric_alarm" "alarma_errores_lambda_recorte" {
  alarm_name          = "${var.nombreBase}-crop-errors-alarm"
  alarm_description   = "La Lambda de recorte tuvo errores en los ultimos 5 minutos."
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = local.nombreFuncionRecorte
  }

  alarm_actions = [aws_sns_topic.topico_alertas.arn]
}