variable "nombreBase" {
  description = "Prefijo de los nombres de los recursos."
  type        = string
}

variable "permitirDestruccionBucket" {
  description = "true permite que terraform destroy borre el bucket aunque tenga imágenes. En prod va en false."
  type        = bool
}