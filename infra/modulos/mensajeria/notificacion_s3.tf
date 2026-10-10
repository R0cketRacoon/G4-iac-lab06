resource "aws_s3_bucket_notification" "notificacion_nuevas_imagenes" {
  bucket = var.idBucketImagenes

  dynamic "queue" {
    for_each = toset(var.extensionesPermitidas)

    content {
      id            = "nueva-imagen${replace(queue.value, ".", "-")}"
      queue_arn     = aws_sqs_queue.cola_procesamiento_imagenes.arn
      events        = ["s3:ObjectCreated:*"]
      filter_prefix = var.prefijoOriginales
      filter_suffix = queue.value
    }
  }

  depends_on = [aws_sqs_queue_policy.politica_cola_eventos_s3]
}