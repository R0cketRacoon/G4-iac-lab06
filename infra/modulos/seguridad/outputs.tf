output "idGrupoSeguridadLambdaCarga" {
  description = "Grupo de seguridad de la Lambda de carga."
  value       = aws_security_group.grupo_seguridad_lambda_carga.id
}

output "idGrupoSeguridadLambdaRecorte" {
  description = "Grupo de seguridad de la Lambda de recorte."
  value       = aws_security_group.grupo_seguridad_lambda_recorte.id
}