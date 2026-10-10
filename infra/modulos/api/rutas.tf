# Ruta del diagrama: la imagen viaja dentro de la petición (hasta 4 MB).
resource "aws_apigatewayv2_route" "ruta_subir_imagen" {
  api_id    = aws_apigatewayv2_api.api_carga_imagenes.id
  route_key = "POST /upload"
  target    = "integrations/${aws_apigatewayv2_integration.integracion_lambda_carga.id}"
}

# Ruta agregada: devuelve un formulario firmado para subir directo a S3
# imágenes de hasta 10 MB, que no caben por la ruta anterior.
resource "aws_apigatewayv2_route" "ruta_solicitar_url_prefirmada" {
  api_id    = aws_apigatewayv2_api.api_carga_imagenes.id
  route_key = "POST /upload-url"
  target    = "integrations/${aws_apigatewayv2_integration.integracion_lambda_carga.id}"
}

# Permiso para que este API (y solo este) invoque la Lambda.
resource "aws_lambda_permission" "permiso_api_invocar_carga" {
  statement_id  = "PermitirInvocacionDesdeHttpApi"
  action        = "lambda:InvokeFunction"
  function_name = var.nombreFuncionCarga
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api_carga_imagenes.execution_arn}/*/*"
}