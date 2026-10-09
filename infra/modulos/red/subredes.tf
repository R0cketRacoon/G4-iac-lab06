resource "aws_subnet" "subred_publica" {
  count = length(var.zonasDisponibilidad)

  vpc_id                  = aws_vpc.red_principal.id
  cidr_block              = var.cidrsSubredesPublicas[count.index]
  availability_zone       = var.zonasDisponibilidad[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.nombreBase}-public-${substr(var.zonasDisponibilidad[count.index], -1, 1)}"
    Tipo = "publica"
  }
}

resource "aws_subnet" "subred_privada" {
  count = length(var.zonasDisponibilidad)

  vpc_id            = aws_vpc.red_principal.id
  cidr_block        = var.cidrsSubredesPrivadas[count.index]
  availability_zone = var.zonasDisponibilidad[count.index]

  tags = {
    Name = "${var.nombreBase}-private-${substr(var.zonasDisponibilidad[count.index], -1, 1)}"
    Tipo = "privada"
  }
}