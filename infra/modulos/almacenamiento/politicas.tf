
data "aws_iam_policy_document" "politica_solo_https" {
  statement {
    sid     = "RechazarTraficoSinTls"
    effect  = "Deny"
    actions = ["s3:*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    resources = [
      aws_s3_bucket.bucket_imagenes.arn,
      "${aws_s3_bucket.bucket_imagenes.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "politica_bucket_imagenes" {
  bucket = aws_s3_bucket.bucket_imagenes.id
  policy = data.aws_iam_policy_document.politica_solo_https.json

  depends_on = [aws_s3_bucket_public_access_block.bloqueo_acceso_publico]
}