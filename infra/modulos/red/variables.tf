variable "nombreBase" {
  description = "Prefijo de todos los nombres, por ejemplo image-processor-dev."
  type        = string
}

variable "cidrVpc" {
  description = "Rango de IPs de la VPC."
  type        = string

  validation {
    condition     = can(cidrhost(var.cidrVpc, 0))
    error_message = "El valor de cidrVpc no es un CIDR válido."
  }
}

variable "zonasDisponibilidad" {
  description = "Zonas donde se reparten las subredes (exactamente 2)."
  type        = list(string)

  validation {
    condition     = length(var.zonasDisponibilidad) == 2
    error_message = "La arquitectura está pensada para exactamente dos zonas de disponibilidad."
  }
}

variable "cidrsSubredesPublicas" {
  description = "Un CIDR por zona para las subredes públicas."
  type        = list(string)
}

variable "cidrsSubredesPrivadas" {
  description = "Un CIDR por zona para las subredes privadas."
  type        = list(string)
}

variable "cantidadNatGateways" {
  description = "0 = sin NAT (trampa corregida), 1 = un NAT, 2 = dos NAT."
  type        = number
  default     = 0

  validation {
    condition     = contains([0, 1, 2], var.cantidadNatGateways)
    error_message = "cantidadNatGateways solo acepta 0, 1 o 2."
  }
}