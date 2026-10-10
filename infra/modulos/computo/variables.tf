variable "nombreFuncionCarga" {
  description = "Nombre de la Lambda de carga (lo define el módulo de observabilidad)."
  type        = string
}

variable "nombreFuncionRecorte" {
  description = "Nombre de la Lambda de recorte."
  type        = string
}

variable "nombreGrupoLogsCarga" {
  description = "Log group ya creado para la Lambda de carga."
  type        = string
}

variable "nombreGrupoLogsRecorte" {
  description = "Log group ya creado para la Lambda de recorte."
  type        = string
}

variable "runtimeLambda" {
  description = "Runtime de Node.js. El enunciado exige Node.js 24; el nodejs20.x del diagrama está deprecado (ADR 0001)."
  type        = string
  default     = "nodejs24.x"
}

variable "rutaPaqueteCarga" {
  description = "Ruta al zip de la Lambda de carga (lo genera Docker en app/dist)."
  type        = string
}

variable "rutaPaqueteRecorte" {
  description = "Ruta al zip de la Lambda de recorte."
  type        = string
}

variable "arnRolLambdaCarga" {
  description = "Rol IAM de la Lambda de carga."
  type        = string
}

variable "arnRolLambdaRecorte" {
  description = "Rol IAM de la Lambda de recorte."
  type        = string
}

variable "idsSubredesPrivadas" {
  description = "Subredes privadas de las dos zonas."
  type        = list(string)
}

variable "idGrupoSeguridadLambdaCarga" {
  description = "Grupo de seguridad de la Lambda de carga."
  type        = string
}

variable "idGrupoSeguridadLambdaRecorte" {
  description = "Grupo de seguridad de la Lambda de recorte."
  type        = string
}

variable "nombreBucketImagenes" {
  description = "Bucket donde se leen y escriben las imágenes."
  type        = string
}

variable "prefijoOriginales" {
  description = "Carpeta de originales."
  type        = string
  default     = "uploads/"
}

variable "prefijoProcesadas" {
  description = "Carpeta de procesadas."
  type        = string
  default     = "processed/"
}

variable "memoriaCargaMb" {
  description = "Memoria de la Lambda de carga."
  type        = number
  default     = 256
}

variable "segundosTimeoutCarga" {
  description = "Tiempo máximo de la Lambda de carga. No puede pasar de 30: es el límite de API Gateway."
  type        = number
  default     = 30
}

variable "memoriaRecorteMb" {
  description = "Memoria de la Lambda de recorte. sharp trabaja en memoria, por eso el doble."
  type        = number
  default     = 512
}

variable "segundosTimeoutRecorte" {
  description = "Tiempo máximo de la Lambda de recorte. La cola usa 6 veces este valor."
  type        = number
  default     = 60
}

variable "tamanoMaximoCargaDirectaMb" {
  description = "Tope para POST /upload. Lambda acepta 6 MB y el base64 infla un 33 %, por eso 4."
  type        = number
  default     = 4
}

variable "tamanoMaximoUrlPrefirmadaMb" {
  description = "Tope para subidas con formulario prefirmado (POST /upload-url)."
  type        = number
  default     = 10
}

variable "segundosValidezUrlPrefirmada" {
  description = "Minutos de vida del formulario prefirmado, expresados en segundos."
  type        = number
  default     = 300
}

variable "arnColaProcesamiento" {
  description = "Cola que dispara la Lambda de recorte."
  type        = string
}

variable "tamanoLoteSqs" {
  description = "Mensajes que recibe la Lambda de recorte en cada invocación."
  type        = number
  default     = 5
}

variable "concurrenciaMaximaRecorte" {
  description = "Máximo de Lambdas de recorte corriendo a la vez. Mínimo permitido por AWS: 2."
  type        = number
  default     = 2

  validation {
    condition     = var.concurrenciaMaximaRecorte >= 2
    error_message = "AWS exige que la concurrencia máxima del disparador SQS sea al menos 2."
  }
}