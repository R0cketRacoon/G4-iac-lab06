resource "aws_route_table" "tabla_rutas_publica" {
  vpc_id = aws_vpc.red_principal.id

  tags = {
    Name = "${var.nombreBase}-public-rt"
  }
}

resource "aws_route" "ruta_publica_hacia_internet" {
  route_table_id         = aws_route_table.tabla_rutas_publica.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.puerta_enlace_internet.id
}

resource "aws_route_table_association" "asociacion_subred_publica" {
  count = length(aws_subnet.subred_publica)

  subnet_id      = aws_subnet.subred_publica[count.index].id
  route_table_id = aws_route_table.tabla_rutas_publica.id
}

resource "aws_route_table" "tabla_rutas_privada" {
  count  = length(aws_subnet.subred_privada)
  vpc_id = aws_vpc.red_principal.id

  tags = {
    Name = "${var.nombreBase}-private-rt-${substr(var.zonasDisponibilidad[count.index], -1, 1)}"
  }
}

resource "aws_route" "ruta_privada_hacia_nat" {
  count = var.cantidadNatGateways > 0 ? length(aws_route_table.tabla_rutas_privada) : 0

  route_table_id         = aws_route_table.tabla_rutas_privada[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.puerta_enlace_nat[*].id, count.index)
}

resource "aws_route_table_association" "asociacion_subred_privada" {
  count = length(aws_subnet.subred_privada)

  subnet_id      = aws_subnet.subred_privada[count.index].id
  route_table_id = aws_route_table.tabla_rutas_privada[count.index].id
}