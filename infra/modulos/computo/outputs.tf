output "nombreFuncionCarga" {
  description = "Nombre de la Lambda de carga."
  value       = aws_lambda_function.funcion_carga_imagenes.function_name
}

output "arnInvocacionFuncionCarga" {
  description = "ARN de invocación que necesita API Gateway."
  value       = aws_lambda_function.funcion_carga_imagenes.invoke_arn
}

output "nombreFuncionRecorte" {
  description = "Nombre de la Lambda de recorte."
  value       = aws_lambda_function.funcion_recorte_circular.function_name
}