# Etapa $default con auto-deploy: cualquier cambio en rutas se publica
# solo, sin pasos manuales. Aquí también va el límite de peticiones y el
# formato de los access logs.
resource "aws_apigatewayv2_stage" "etapa_por_defecto" {
  api_id      = aws_apigatewayv2_api.api_carga_imagenes.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_rate_limit  = var.limitePeticionesPorSegundo
    throttling_burst_limit = var.limiteRafaga
  }

  access_log_settings {
    destination_arn = var.arnGrupoLogsApi
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      fecha          = "$context.requestTime"
      metodo         = "$context.httpMethod"
      ruta           = "$context.routeKey"
      estado         = "$context.status"
      bytesRespuesta = "$context.responseLength"
      latenciaMs     = "$context.responseLatency"
      errorLambda    = "$context.integrationErrorMessage"
      userAgent      = "$context.identity.userAgent"
    })
  }
}