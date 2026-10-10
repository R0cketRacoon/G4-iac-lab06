output "nombreGrupoLogsCarga" {
  description = "Log group de la Lambda de carga."
  value       = aws_cloudwatch_log_group.logs_lambda_carga.name
}

output "nombreGrupoLogsRecorte" {
  description = "Log group de la Lambda de recorte."
  value       = aws_cloudwatch_log_group.logs_lambda_recorte.name
}

output "arnGrupoLogsApi" {
  description = "Log group de los access logs de API Gateway."
  value       = aws_cloudwatch_log_group.logs_api_gateway.arn
}

output "arnTopicoAlertas" {
  description = "Tópico SNS de alertas."
  value       = aws_sns_topic.topico_alertas.arn
}

output "nombreFuncionCarga" {
  description = "Nombre que debe usar la Lambda de carga."
  value       = local.nombreFuncionCarga
}

output "nombreFuncionRecorte" {
  description = "Nombre que debe usar la Lambda de recorte."
  value       = local.nombreFuncionRecorte
}