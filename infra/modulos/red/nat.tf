resource "aws_eip" "ip_elastica_nat" {
  count  = var.cantidadNatGateways
  domain = "vpc"

  tags = {
    Name = "${var.nombreBase}-nat-eip-${substr(var.zonasDisponibilidad[count.index], -1, 1)}"
  }

  depends_on = [aws_internet_gateway.puerta_enlace_internet]
}

resource "aws_nat_gateway" "puerta_enlace_nat" {
  count = var.cantidadNatGateways

  allocation_id = aws_eip.ip_elastica_nat[count.index].id
  subnet_id     = aws_subnet.subred_publica[count.index].id

  tags = {
    Name = "${var.nombreBase}-nat-${substr(var.zonasDisponibilidad[count.index], -1, 1)}"
  }

  depends_on = [aws_internet_gateway.puerta_enlace_internet]
}