variable "nombreBase" {
  description = "Prefijo de los nombres de los recursos."
  type        = string
}

variable "segundosVisibilidad" {
  description = "Tiempo que un mensaje queda oculto mientras se procesa. AWS recomienda 6 veces el timeout de la Lambda (6 x 60 s)."
  type        = number
  default     = 360
}

variable "segundosRetencionCola" {
  description = "Tiempo máximo que un mensaje espera en la cola principal (1 día)."
  type        = number
  default     = 86400
}

variable "segundosRetencionDlq" {
  description = "Tiempo que se guardan los mensajes fallidos para investigarlos (14 días)."
  type        = number
  default     = 1209600
}

variable "segundosEsperaLongPolling" {
  description = "Long polling: cuánto espera una lectura antes de responder vacía. Ahorra peticiones."
  type        = number
  default     = 20
}

variable "maximoRecepcionesAntesDlq" {
  description = "Intentos antes de mandar el mensaje a la cola de fallidos."
  type        = number
  default     = 3
}

variable "idBucketImagenes" {
  description = "Bucket que dispara las notificaciones."
  type        = string
}

variable "arnBucketImagenes" {
  description = "ARN del bucket, para que solo él pueda escribir en la cola."
  type        = string
}

variable "prefijoOriginales" {
  description = "Solo los objetos bajo este prefijo generan mensaje. Evita un bucle con processed/."
  type        = string
  default     = "uploads/"
}

variable "extensionesPermitidas" {
  description = "Extensiones que disparan el procesamiento."
  type        = list(string)
  default     = [".jpg", ".jpeg", ".png", ".gif", ".webp"]
}