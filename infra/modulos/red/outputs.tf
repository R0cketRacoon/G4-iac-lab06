output "idVpc" {
  description = "ID de la VPC creada."
  value       = aws_vpc.red_principal.id
}

output "idsSubredesPublicas" {
  description = "Subredes públicas, una por zona."
  value       = aws_subnet.subred_publica[*].id
}

output "idsSubredesPrivadas" {
  description = "Subredes privadas donde se conectan las Lambdas."
  value       = aws_subnet.subred_privada[*].id
}

output "idsTablasRutasPrivadas" {
  description = "Tablas de rutas privadas, necesarias para inyectar el endpoint de S3."
  value       = aws_route_table.tabla_rutas_privada[*].id
}

output "ipsPublicasNat" {
  description = "IPs fijas de salida a internet. Vacío si el entorno no tiene NAT."
  value       = aws_eip.ip_elastica_nat[*].public_ip
}