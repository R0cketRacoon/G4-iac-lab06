# Este módulo solo declara qué proveedor necesita. La configuración real
# (región, etiquetas por defecto, credenciales) la pone cada entorno.
terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.80, < 7.0"
    }
  }
}