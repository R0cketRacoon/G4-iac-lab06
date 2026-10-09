resource "aws_vpc" "red_principal" {
  cidr_block           = var.cidrVpc
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.nombreBase}-vpc"
  }
}

resource "aws_internet_gateway" "puerta_enlace_internet" {
  vpc_id = aws_vpc.red_principal.id

  tags = {
    Name = "${var.nombreBase}-igw"
  }
}