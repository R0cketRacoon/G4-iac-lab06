resource "aws_security_group" "grupo_seguridad_lambda_carga" {
  name        = "${var.nombreBase}-sg-upload-lambda"
  description = "Lambda de carga: sin entrada, solo sale a S3 por el gateway endpoint"
  vpc_id      = var.idVpc

  tags = {
    Name = "${var.nombreBase}-sg-upload-lambda"
  }
}

resource "aws_security_group" "grupo_seguridad_lambda_recorte" {
  name        = "${var.nombreBase}-sg-crop-lambda"
  description = "Lambda de recorte: sin entrada, solo sale a S3 por el gateway endpoint"
  vpc_id      = var.idVpc

  tags = {
    Name = "${var.nombreBase}-sg-crop-lambda"
  }
}