resource "aws_vpc_endpoint" "endpoint_gateway_s3" {
  vpc_id            = var.idVpc
  service_name      = "com.amazonaws.${var.regionAws}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.idsTablasRutasPrivadas

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "SoloBucketDeImagenes"
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:GetObject", "s3:PutObject"]
        Resource  = "${var.arnBucketImagenes}/*"
      }
    ]
  })

  tags = {
    Name = "${var.nombreBase}-vpce-s3"
  }
}