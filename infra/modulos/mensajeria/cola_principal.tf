resource "aws_sqs_queue" "cola_procesamiento_imagenes" {
  name                       = "${var.nombreBase}-image-queue"
  visibility_timeout_seconds = var.segundosVisibilidad
  message_retention_seconds  = var.segundosRetencionCola
  receive_wait_time_seconds  = var.segundosEsperaLongPolling
  sqs_managed_sse_enabled    = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.cola_mensajes_fallidos.arn
    maxReceiveCount     = var.maximoRecepcionesAntesDlq
  })

  tags = {
    Name = "${var.nombreBase}-image-queue"
  }
}