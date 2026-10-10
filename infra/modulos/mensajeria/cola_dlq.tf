# Cola de mensajes fallidos (DLQ).
resource "aws_sqs_queue" "cola_mensajes_fallidos" {
  name                      = "${var.nombreBase}-image-dlq"
  message_retention_seconds = var.segundosRetencionDlq
  sqs_managed_sse_enabled   = true

  tags = {
    Name = "${var.nombreBase}-image-dlq"
  }
}

resource "aws_sqs_queue_redrive_allow_policy" "permiso_redrive_dlq" {
  queue_url = aws_sqs_queue.cola_mensajes_fallidos.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.cola_procesamiento_imagenes.arn]
  })
}