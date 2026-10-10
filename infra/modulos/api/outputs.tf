output "urlBaseApi" {
  description = "URL base del API."
  value       = aws_apigatewayv2_api.api_carga_imagenes.api_endpoint
}

output "idApi" {
  description = "ID del HTTP API."
  value       = aws_apigatewayv2_api.api_carga_imagenes.id
}