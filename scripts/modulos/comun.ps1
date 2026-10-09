# -----------------------------------------------------------------------------
# Funciones compartidas por todos los comandos de "proyecto".
# Funcionan igual dentro del contenedor (Linux) y en Windows con PowerShell 7.
# -----------------------------------------------------------------------------
$ErrorActionPreference = 'Stop'

$script:raizRepositorio = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$script:entornosValidos = @('dev', 'qa', 'prod')
$script:enCi = $env:CI -eq 'true'

function Escribir-Paso([string]$texto) { Write-Host ''; Write-Host "==> $texto" -ForegroundColor Cyan }
function Escribir-Ok([string]$texto) { Write-Host " OK $texto" -ForegroundColor Green }
function Escribir-Aviso([string]$texto) { Write-Host " !! $texto" -ForegroundColor Yellow }
function Escribir-Error([string]$texto) { Write-Host " XX $texto" -ForegroundColor Red }

function Confirmar-ExitoComando([string]$queSeHacia) {
  if ($LASTEXITCODE -ne 0) {
      throw "Falló: $queSeHacia (código $LASTEXITCODE). Revisa el mensaje de arriba."
  }
}

function Validar-Entorno([string]$entorno) {
  if ($entorno -notin $script:entornosValidos) {
      throw "Indica un entorno válido: dev, qa o prod. Ejemplo: proyecto desplegar dev"
  }
}

function Confirmar-Accion([string]$mensaje, [string]$respuestaEsperada) {
  if ($script:enCi) { return $true }
  $respuesta = Read-Host "$mensaje Escribe '$respuestaEsperada' para continuar"
  return $respuesta -eq $respuestaEsperada
}

function Leer-ArchivoEnv {
  $ruta = Join-Path $script:raizRepositorio '.env'
  if (-not (Test-Path $ruta)) { return }

  foreach ($linea in Get-Content $ruta) {
      $limpia = $linea.Trim()
      if (-not $limpia -or $limpia.StartsWith('#') -or -not $limpia.Contains('=')) { continue }
      $clave, $valor = $limpia.Split('=', 2)
      $clave = $clave.Trim()
      $valor = $valor.Trim().Trim('"').Trim("'")
      if (-not [Environment]::GetEnvironmentVariable($clave)) {
          [Environment]::SetEnvironmentVariable($clave, $valor)
      }
  }
}

function Leer-Valor([string]$clave, [string]$porDefecto = '') {
  $valor = [Environment]::GetEnvironmentVariable($clave)
  if ([string]::IsNullOrWhiteSpace($valor)) { return $porDefecto }
  return $valor
}

function Cargar-Configuracion {
  Leer-ArchivoEnv

  $script:idCuentaAws = Leer-Valor 'ID_CUENTA_AWS'
  $script:regionAws = Leer-Valor 'REGION_AWS' 'us-east-1'
  $script:perfilAws = Leer-Valor 'PERFIL_AWS'
  $script:nombreProyecto = Leer-Valor 'NOMBRE_PROYECTO' 'image-processor'
  $script:organizacionGithub = Leer-Valor 'ORGANIZACION_GITHUB'
  $script:repositorioGithub = Leer-Valor 'REPOSITORIO_GITHUB' 'image-processor-iac'
  $script:correoAlertas = Leer-Valor 'CORREO_ALERTAS'
  $script:crearProveedorOidc = Leer-Valor 'CREAR_PROVEEDOR_OIDC' 'true'
  $script:bucketEstado = Leer-Valor 'BUCKET_ESTADO' "$($script:nombreProyecto)-tfstate-$($script:idCuentaAws)"

  $env:AWS_REGION = $script:regionAws
  $env:AWS_DEFAULT_REGION = $script:regionAws
  if ($script:perfilAws) { $env:AWS_PROFILE = $script:perfilAws }

  $env:TF_VAR_idCuentaAws = $script:idCuentaAws
  $env:TF_VAR_perfilAws = $script:perfilAws
  $env:TF_VAR_regionAws = $script:regionAws
  $env:TF_VAR_nombreProyecto = $script:nombreProyecto
  $env:TF_VAR_correoAlertas = $script:correoAlertas
  $env:TF_VAR_organizacionGithub = $script:organizacionGithub
  $env:TF_VAR_repositorioGithub = $script:repositorioGithub
  $env:TF_VAR_crearProveedorOidc = $script:crearProveedorOidc

  if ($script:organizacionGithub) {
      $env:TF_VAR_repositorioGit = "https://github.com/$($script:organizacionGithub)/$($script:repositorioGithub)"
  }
}

function Revisar-Configuracion {
  $problemas = @()

  if ($script:idCuentaAws -notmatch '^\d{12}$') {
      $problemas += 'ID_CUENTA_AWS debe tener 12 dígitos (sin < >).'
  }

  if (-not $script:organizacionGithub -or $script:organizacionGithub.StartsWith('<')) {
      $problemas += 'Completa ORGANIZACION_GITHUB.'
  }

  if (-not $script:perfilAws) {
      $problemas += 'Completa PERFIL_AWS: el proyecto solo se conecta a AWS con perfiles de AWS CLI.'
  }

  return $problemas
}

function Obtener-CuentaDeLaSesion {
  if (-not (Get-Command aws -ErrorAction SilentlyContinue)) { return $null }

  $id = aws sts get-caller-identity --query Account --output text 2>$null

  if ($LASTEXITCODE -ne 0) { return $null }

  return "$id".Trim()
}

function Exigir-CuentaCorrecta {
  $problemas = Revisar-Configuracion

  if ($problemas) {
      $problemas | ForEach-Object { Escribir-Error $_ }
      throw 'El archivo .env está incompleto. Ejecuta "proyecto verificar".'
  }

  $cuentaSesion = Obtener-CuentaDeLaSesion

  if (-not $cuentaSesion) {
      throw 'No hay sesión de AWS válida. Ejecuta "proyecto iniciar-sesion".'
  }

  if ($cuentaSesion -ne $script:idCuentaAws) {
      throw "La sesión es de la cuenta $cuentaSesion, pero el .env dice $($script:idCuentaAws). No se toca nada."
  }

  Escribir-Ok "Cuenta de AWS: $cuentaSesion ($($script:regionAws))"
}

function Obtener-CarpetaEntorno([string]$entorno) {
  return Join-Path $script:raizRepositorio "infra/entornos/$entorno"
}

function Obtener-SalidaTerraform([string]$entorno, [string]$nombre) {
  $valor = terraform "-chdir=$(Obtener-CarpetaEntorno $entorno)" output -raw $nombre
  Confirmar-ExitoComando "leer el output '$nombre' de $entorno"
  return "$valor".Trim()
}