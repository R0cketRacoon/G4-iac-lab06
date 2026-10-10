variable "nombreBase" {
  description = "Prefijo de los nombres de los recursos."
  type        = string
}

variable "idVpc" {
  description = "VPC donde se crean los grupos de seguridad."
  type        = string
}

variable "regionAws" {
  description = "Región, se usa para encontrar la lista de prefijos de S3."
  type        = string
}