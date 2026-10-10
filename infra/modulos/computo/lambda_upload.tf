# Lambda de carga. Recibe la imagen desde API Gateway, la valida y la
# guarda en uploads/. También entrega formularios prefirmados para
# imágenes de hasta 10 MB que no caben por API Gateway + Lambda.
#
# Hay UNA sola función con interfaces en las dos subredes privadas. Las
# "réplicas AZ-b" del diagrama no son funciones aparte: Lambda reparte
# solo sus ejecuciones entre zonas.
resource "aws_lambda_function" "funcion_carga_imagenes" {
  function_name    = var.nombreFuncionCarga
  description      = "Recibe imagenes por HTTP y las guarda en uploads/"
  role             = var.arnRolLambdaCarga
  runtime          = var.runtimeLambda
  handler          = "index.handler"
  architectures    = ["x86_64"]
  memory_size      = var.memoriaCargaMb
  timeout          = var.segundosTimeoutCarga
  filename         = var.rutaPaqueteCarga
  source_code_hash = filebase64sha256(var.rutaPaqueteCarga)

  environment {
    # S3_BUCKET y UPLOAD_PREFIX son las del diagrama. Las demás existen por la
    # ruta POST /upload-url, que se agregó para poder llegar a los 10 MB.
    variables = {
      S3_BUCKET                 = var.nombreBucketImagenes
      UPLOAD_PREFIX             = var.prefijoOriginales
      PROCESSED_PREFIX          = var.prefijoProcesadas
      MAX_DIRECT_BYTES          = tostring(var.tamanoMaximoCargaDirectaMb * 1024 * 1024)
      MAX_PRESIGNED_BYTES       = tostring(var.tamanoMaximoUrlPrefirmadaMb * 1024 * 1024)
      PRESIGNED_EXPIRES_SECONDS = tostring(var.segundosValidezUrlPrefirmada)
    }
  }

  vpc_config {
    subnet_ids         = var.idsSubredesPrivadas
    security_group_ids = [var.idGrupoSeguridadLambdaCarga]
  }

  # Los logs van al log group que ya creó Terraform, con retención de
  # 14 días y formato JSON para poder filtrarlos en CloudWatch.
  logging_config {
    log_format = "JSON"
    log_group  = var.nombreGrupoLogsCarga
  }
}