output "arnColaProcesamiento" {
  description = "ARN de la cola principal."
  value       = aws_sqs_queue.cola_procesamiento_imagenes.arn
}

output "nombreColaProcesamiento" {
  description = "Nombre de la cola principal."
  value       = aws_sqs_queue.cola_procesamiento_imagenes.name
}

output "urlColaProcesamiento" {
  description = "URL de la cola principal, útil para revisar mensajes por CLI."
  value       = aws_sqs_queue.cola_procesamiento_imagenes.id
}

output "nombreColaFallidos" {
  description = "Nombre de la DLQ, lo usa la alarma."
  value       = aws_sqs_queue.cola_mensajes_fallidos.name
}

output "urlColaFallidos" {
  description = "URL de la DLQ."
  value       = aws_sqs_queue.cola_mensajes_fallidos.id
}