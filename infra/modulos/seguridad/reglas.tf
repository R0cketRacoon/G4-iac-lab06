data "aws_prefix_list" "lista_prefijos_s3" {
  name = "com.amazonaws.${var.regionAws}.s3"
}

resource "aws_vpc_security_group_egress_rule" "salida_carga_hacia_s3" {
  security_group_id = aws_security_group.grupo_seguridad_lambda_carga.id
  description       = "HTTPS hacia S3 por el gateway endpoint"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  prefix_list_id    = data.aws_prefix_list.lista_prefijos_s3.id
}

resource "aws_vpc_security_group_egress_rule" "salida_recorte_hacia_s3" {
  security_group_id = aws_security_group.grupo_seguridad_lambda_recorte.id
  description       = "HTTPS hacia S3 por el gateway endpoint"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  prefix_list_id    = data.aws_prefix_list.lista_prefijos_s3.id
}