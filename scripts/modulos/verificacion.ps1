# -----------------------------------------------------------------------------
# "proyecto verificar" y "proyecto iniciar-sesion"
# -----------------------------------------------------------------------------
function Comando-Verificar {
  $todoBien = $true

  Escribir-Paso 'Herramientas'
  foreach ($herramienta in 'terraform', 'aws', 'node', 'npm', 'tflint') {
    $comando = Get-Command $herramienta -ErrorAction SilentlyContinue
    if ($comando) { Escribir-Ok "$herramienta disponible" }
    elseif ($herramienta -eq 'tflint') { Escribir-Aviso 'tflint no está (opcional fuera del contenedor)' }
    else { Escribir-Error "Falta $herramienta. Usa el contenedor o revisa el anexo de instalación."; $todoBien = $false }
  }

  if ($env:EN_CONTENEDOR -eq 'true') {
    Escribir-Ok 'Ejecutando dentro del contenedor de herramientas'
  }

  Escribir-Paso 'Archivo .env'
  if (-not $script:enCi -and -not (Test-Path (Join-Path $script:raizRepositorio '.env'))) {
    Escribir-Error 'No existe .env. Crea uno con: Copy-Item .env.example .env'
    return
  }

  $problemas = Revisar-Configuracion

  if ($problemas) {
    $problemas | ForEach-Object { Escribir-Error $_ }
    $todoBien = $false
  }
  else {
    Escribir-Ok "Proyecto $($script:nombreProyecto), cuenta $($script:idCuentaAws), región $($script:regionAws)"
  }

  Escribir-Paso 'Sesión de AWS'
  $cuentaSesion = Obtener-CuentaDeLaSesion

  if (-not $cuentaSesion) {
    Escribir-Error 'Sin sesión válida. Ejecuta: proyecto iniciar-sesion'
    $todoBien = $false
  }
  elseif ($cuentaSesion -ne $script:idCuentaAws) {
    Escribir-Error "La sesión es de la cuenta $cuentaSesion y el .env dice $($script:idCuentaAws)."
    $todoBien = $false
  }
  else {
    Escribir-Ok "Sesión activa en la cuenta $cuentaSesion"

    Escribir-Paso 'Estado remoto'
    aws s3api head-bucket --bucket $script:bucketEstado 2>$null | Out-Null

    if ($LASTEXITCODE -eq 0) {
      Escribir-Ok "Existe el bucket $($script:bucketEstado)"
    }
    else {
      Escribir-Aviso "No existe $($script:bucketEstado). Si eres el primero en esta cuenta: proyecto bootstrap"
    }
  }

  Write-Host ''

  if ($todoBien) {
    Write-Host 'Todo listo. Siguiente paso sugerido: proyecto desplegar dev' -ForegroundColor Green
  }
  else {
    Write-Host 'Corrige lo marcado con XX y vuelve a ejecutar: proyecto verificar' -ForegroundColor Yellow
  }
}

function Comando-IniciarSesion {
  if (-not $script:perfilAws) {
    throw 'Completa PERFIL_AWS en el .env (el perfil creado con "aws configure sso").'
  }

  Escribir-Paso "Iniciando sesión con el perfil $($script:perfilAws)"

  aws sso login --profile $script:perfilAws --use-device-code
  Confirmar-ExitoComando 'iniciar sesión en AWS'

  $cuenta = Obtener-CuentaDeLaSesion
  Escribir-Ok "Sesión iniciada en la cuenta $cuenta"
}

function Comando-ConfigurarSso {
  Escribir-Paso 'Configuración del perfil de AWS (una sola vez por integrante)'

  Write-Host ' Ten a mano la URL del portal de AWS (https://d-xxxxxxxxxx.awsapps.com/start).'

  aws configure sso --profile $(if ($script:perfilAws) { $script:perfilAws } else { 'image-processor' }) --use-device-code
  Confirmar-ExitoComando 'configurar el perfil SSO'
}