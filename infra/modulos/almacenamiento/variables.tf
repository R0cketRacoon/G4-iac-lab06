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
variable "prefijoOriginales" {
  description = "Carpeta donde caen las imágenes que sube el cliente."
  type        = string
  default     = "uploads/"
}

variable "prefijoProcesadas" {
  description = "Carpeta donde la Lambda de recorte deja los PNG circulares."
  type        = string
  default     = "processed/"
}

variable "diasExpiracionOriginales" {
  description = "Días que se guarda una imagen original antes de borrarse sola."
  type        = number
  default     = 30
}

variable "diasExpiracionProcesadas" {
  description = "Días que se guarda una imagen procesada antes de borrarse sola."
  type        = number
  default     = 90
}

variable "diasExpiracionVersionesAnteriores" {
  description = "Días que se guardan las versiones reemplazadas o borradas. Sin esto se acumulan para siempre."
  type        = number
  default     = 7
}