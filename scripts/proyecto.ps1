<#
.SYNOPSIS
 Punto de entrada único del proyecto Image Processor.

.DESCRIPTION
 Dentro del Dev Container:  proyecto <comando> [entorno]
 Con Docker Compose:        docker compose run --rm herramientas <comando> [entorno]
 En Windows (anexo, sin Docker): pwsh ./scripts/proyecto.ps1 <comando> [entorno]

.EXAMPLE
  proyecto verificar
  proyecto desplegar dev
  proyecto probar dev -Caso corrupto
#>
param(
   [Parameter(Position = 0)] [string]$Comando = 'ayuda',
   [Parameter(Position = 1)] [string]$Entorno,
   [string]$Caso = 'todos',
   [switch]$Destruir
)

foreach ($modulo in 'comun', 'verificacion', 'construccion', 'terraform', 'pruebas_api', 'evidencias') {
  . (Join-Path $PSScriptRoot "modulos/$modulo.ps1")
}

function Mostrar-Ayuda {
  Write-Host @'

 Image Processor - comandos disponibles

 Preparación
  verificar          Revisa herramientas, .env, sesión de AWS y estado remoto
  configurar-sso     Crea tu perfil de AWS SSO (una sola vez)
  iniciar-sesion     Inicia sesión en AWS (código en el navegador)
  bootstrap [-Destruir] Crea (o borra) el bucket de estado y el rol de GitHub

 Desarrollo
  construir          Empaqueta las Lambdas para Linux en app/dist
  pruebas            Ejecuta las pruebas unitarias de las Lambdas
  validar            fmt + validate + tflint + pruebas (lo mismo que el pipeline)

 Entornos (dev | qa | prod)
  iniciar <entorno>      Conecta el entorno con el estado remoto
  plan <entorno>         Muestra qué cambiaría, sin tocar nada
  desplegar <entorno>    Plan + apply
  salidas <entorno>      URL del API, bucket, colas...
  probar <entorno> [-Caso x] Prueba de punta a punta (directo, json, prefirmada, corrupto, todos)
  evidencias <entorno>   Guarda en docs/evidencias lo que existe en AWS
  destruir <entorno>     terraform destroy + verificación
  verificar-destruccion <ent> Comprueba que no quedó nada

'@
}

try {
   Cargar-Configuracion

   switch ($Comando) {
      'ayuda'                 { Mostrar-Ayuda }
      'verificar'             { Comando-Verificar }
      'configurar-sso'        { Comando-ConfigurarSso }
      'iniciar-sesion'        { Comando-IniciarSesion }
      'bootstrap'             { Comando-Bootstrap -Destruir:$Destruir }
      'construir'             { Comando-Construir }
      'pruebas'               { Comando-Pruebas }
      'validar'               { Comando-Validar }
      'iniciar'               { Comando-Iniciar $Entorno }
      'plan'                  { Comando-Plan $Entorno }
      'desplegar'             { Comando-Desplegar $Entorno }
      'salidas'               { Comando-Salidas $Entorno }
      'probar'                { Comando-Probar $Entorno $Caso }
      'evidencias'            { Comando-Evidencias $Entorno }
      'destruir'              { Comando-Destruir $Entorno }
      'verificar-destruccion' { Comando-VerificarDestruccion $Entorno }
      default {
         Escribir-Error "Comando desconocido: $Comando"
         Mostrar-Ayuda
         exit 1
      }
   }
}
catch {
   Escribir-Error $_.Exception.Message
   exit 1
}