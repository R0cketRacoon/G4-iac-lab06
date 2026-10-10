variable "nombreBase" {
  description = "Prefijo de los nombres de los recursos."
  type        = string
}

variable "diasRetencionLogs" {
  description = "Días que se guardan los logs antes de borrarse solos."
  type        = number
  default     = 14
}

variable "nombreColaFallidos" {
  description = "DLQ que vigila la alarma principal."
  type        = string
}

variable "correoAlertas" {
  description = "Correo que recibe las alarmas. Vacío = el tópico se crea pero sin suscriptores."
  type        = string
  default     = ""
}