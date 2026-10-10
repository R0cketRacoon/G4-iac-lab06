
resource "aws_s3_bucket_lifecycle_configuration" "ciclo_vida_imagenes" {
  bucket = aws_s3_bucket.bucket_imagenes.id

  rule {
    id     = "expirar-originales"
    status = "Enabled"

    filter {
      prefix = var.prefijoOriginales
    }

    expiration {
      days = var.diasExpiracionOriginales
    }

    noncurrent_version_expiration {
      noncurrent_days = var.diasExpiracionVersionesAnteriores
    }
  }

  rule {
    id     = "expirar-procesadas"
    status = "Enabled"

    filter {
      prefix = var.prefijoProcesadas
    }

    expiration {
      days = var.diasExpiracionProcesadas
    }

    noncurrent_version_expiration {
      noncurrent_days = var.diasExpiracionVersionesAnteriores
    }
  }

  rule {
    id     = "limpiar-subidas-incompletas"
    status = "Enabled"

    filter {
      prefix = ""
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }

  depends_on = [aws_s3_bucket_versioning.versionado_imagenes]
}