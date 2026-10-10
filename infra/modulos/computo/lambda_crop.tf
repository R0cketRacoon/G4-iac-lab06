# Lambda de recorte. Lee la imagen original, la deja de 40x40 con un
# círculo transparente alrededor y guarda el PNG en processed/.
resource "aws_lambda_function" "funcion_recorte_circular" {
  function_name    = var.nombreFuncionRecorte
  description      = "Recorta imagenes en circulo de 40x40 PNG y las guarda en processed/"
  role             = var.arnRolLambdaRecorte
  runtime          = var.runtimeLambda
  handler          = "index.handler"
  architectures    = ["x86_64"]
  memory_size      = var.memoriaRecorteMb
  timeout          = var.segundosTimeoutRecorte
  filename         = var.rutaPaqueteRecorte
  source_code_hash = filebase64sha256(var.rutaPaqueteRecorte)

  environment {
    # Exactamente las dos variables del diagrama. El tamaño de salida (40x40)
    # y el prefijo de originales usan los valores por defecto del código,
    # que coinciden con el diagrama.
    variables = {
      S3_BUCKET        = var.nombreBucketImagenes
      PROCESSED_PREFIX = var.prefijoProcesadas
    }
  }

  vpc_config {
    subnet_ids         = var.idsSubredesPrivadas
    security_group_ids = [var.idGrupoSeguridadLambdaRecorte]
  }

  logging_config {
    log_format = "JSON"
    log_group  = var.nombreGrupoLogsRecorte
  }
}

# Disparador SQS -> Lambda. Con ReportBatchItemFailures, si en un lote de
# 5 falla una sola imagen, solo esa vuelve a la cola; las otras 4 no se
# reprocesan.
resource "aws_lambda_event_source_mapping" "disparador_cola_recorte" {
  event_source_arn        = var.arnColaProcesamiento
  function_name           = aws_lambda_function.funcion_recorte_circular.arn
  batch_size              = var.tamanoLoteSqs
  function_response_types = ["ReportBatchItemFailures"]

  scaling_config {
    maximum_concurrency = var.concurrenciaMaximaRecorte
  }
}