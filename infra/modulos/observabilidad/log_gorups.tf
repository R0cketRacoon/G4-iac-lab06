resource "aws_cloudwatch_log_group" "logs_lambda_carga" {
  name              = "/aws/lambda/${local.nombreFuncionCarga}"
  retention_in_days = var.diasRetencionLogs
}

resource "aws_cloudwatch_log_group" "logs_lambda_recorte" {
  name              = "/aws/lambda/${local.nombreFuncionRecorte}"
  retention_in_days = var.diasRetencionLogs
}

resource "aws_cloudwatch_log_group" "logs_api_gateway" {
  name              = "/aws/apigateway/${var.nombreBase}-http-api"
  retention_in_days = var.diasRetencionLogs
}