# HTTP API (v2): más barato y más simple que el REST API, y suficiente
# para dos rutas. El endpoint por defecto de execute-api solo acepta
# TLS 1.2 o superior, que es lo que pide el diagrama.
resource "aws_apigatewayv2_api" "api_carga_imagenes" {
  name          = "${var.nombreBase}-http-api"
  description   = "API publica para subir imagenes al procesador"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = var.origenesCorsPermitidos
    allow_methods = ["POST", "OPTIONS"]
    allow_headers = ["content-type"]
    max_age       = 300
  }
}

# Una sola integración para las dos rutas: la Lambda mira routeKey y
# decide qué hacer.
resource "aws_apigatewayv2_integration" "integracion_lambda_carga" {
  api_id                 = aws_apigatewayv2_api.api_carga_imagenes.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.arnInvocacionFuncionCarga
  payload_format_version = "2.0"
  timeout_milliseconds   = 30000
}