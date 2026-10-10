variable "nombreBase" {
  description = "Prefijo de los nombres de los recursos."
  type        = string
}

variable "nombreFuncionCarga" {
  description = "Lambda que atiende las rutas."
  type        = string
}

variable "arnInvocacionFuncionCarga" {
  description = "ARN de invocación de la Lambda de carga."
  type        = string
}

variable "arnGrupoLogsApi" {
  description = "Log group donde caen los access logs."
  type        = string
}

variable "origenesCorsPermitidos" {
  description = "Dominios de navegador que pueden llamar al API."
  type        = list(string)
}

variable "limitePeticionesPorSegundo" {
  description = "Peticiones por segundo sostenidas. Protege la cuenta de abusos y de facturas sorpresa."
  type        = number
}

variable "limiteRafaga" {
  description = "Pico de peticiones que se tolera por unos instantes."
  type        = number
}