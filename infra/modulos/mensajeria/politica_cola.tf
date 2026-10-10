data "aws_caller_identity" "cuenta_actual" {}

data "aws_iam_policy_document" "politica_eventos_desde_s3" {
  statement {
    sid     = "PermitirEventosDelBucketDeImagenes"
    effect  = "Allow"
    actions = ["sqs:SendMessage"]

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    resources = [aws_sqs_queue.cola_procesamiento_imagenes.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [var.arnBucketImagenes]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.cuenta_actual.account_id]
    }
  }
}

resource "aws_sqs_queue_policy" "politica_cola_eventos_s3" {
  queue_url = aws_sqs_queue.cola_procesamiento_imagenes.id
  policy    = data.aws_iam_policy_document.politica_eventos_desde_s3.json
}