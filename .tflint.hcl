# tflint revisa errores que terraform validate no ve: tipos de instancia
# inexistentes, argumentos obsoletos y, sobre todo, nuestras convenciones.

config {
  call_module_type = "local"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "aws" {
  enabled = true
  version = "0.45.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# Convención del proyecto:
#   - variables, outputs y locals en camelCase y en español
#   - recursos, data sources y módulos en snake_case descriptivo
rule "terraform_naming_convention" {
  enabled = true

  variable {
    custom = "^[a-z][a-zA-Z0-9]*$"
  }

  output {
    custom = "^[a-z][a-zA-Z0-9]*$"
  }

  locals {
    custom = "^[a-z][a-zA-Z0-9]*$"
  }

  resource {
    format = "snake_case"
  }

  data {
    format = "snake_case"
  }

  module {
    format = "snake_case"
  }
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}
