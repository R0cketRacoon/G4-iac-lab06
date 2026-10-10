variable "nombreBase" {
  description = "Prefijo de los nombres de los recursos."
  type        = string
}

variable "regionAws" {
  description = "Región donde se crea el endpoint."
  type        = string
}

variable "idVpc" {
  description = "VPC donde se crea el endpoint."
  type        = string
}

variable "idsTablasRutasPrivadas" {
  description = "Tablas de rutas privadas donde se inyecta la ruta hacia S3."
  type        = list(string)
}

variable "arnBucketImagenes" {
  description = "El endpoint de S3 solo deja pasar tráfico hacia este bucket."
  type        = string
}