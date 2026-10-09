variable "nombreBase" {
  description = "Prefijo de los nombres de los recursos."
  type        = string
}

variable "permitirDestruccionBucket" {
  description = "true permite que terraform destroy borre el bucket aunque tenga imágenes. En prod va en false."
  type        = bool
}

variable "origenesCorsPermitidos" {
  description = "Dominios de navegador que pueden subir con URL prefirmada directo a S3."
  type        = list(string)
}