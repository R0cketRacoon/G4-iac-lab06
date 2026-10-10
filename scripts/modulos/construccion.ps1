# -----------------------------------------------------------------------------
# "proyecto construir", "proyecto pruebas" y "proyecto validar"
# -----------------------------------------------------------------------------
Add-Type -AssemblyName System.IO.Compression

$script:funcionesLambda = @('upload-lambda', 'crop-lambda')
$script:carpetaPaquetes = Join-Path $script:raizRepositorio 'app/dist'

# Arma un zip reproducible: rutas con "/", orden fijo, fecha fija y permisos
# de lectura para Linux. Si el código no cambió, el zip sale idéntico y
# Terraform no vuelve a desplegar la Lambda.
function Crear-ZipReproducible([string]$carpetaOrigen, [string]$rutaZip) {
  if (Test-Path $rutaZip) { Remove-Item $rutaZip -Force }
  $fechaFija = [DateTimeOffset]::new(2024, 1, 1, 0, 0, 0, [TimeSpan]::Zero)
  $permisosLectura = [int](0x81A4 -shl 16) # archivo normal, permisos 644

  $archivos = Get-ChildItem -Path $carpetaOrigen -Recurse -File |
      ForEach-Object {
        [pscustomobject]@{
          Ruta = $_.FullName
          Nombre = [IO.Path]::GetRelativePath($carpetaOrigen, $_.FullName).Replace('\', '/')
        }
      } |
      Sort-Object -Property Nombre -Culture ([Globalization.CultureInfo]::InvariantCulture)

  $flujo = [IO.File]::Create($rutaZip)
  $zip = [IO.Compression.ZipArchive]::new($flujo, [IO.Compression.ZipArchiveMode]::Create)

  try {
    foreach ($archivo in $archivos) {
      $entrada = $zip.CreateEntry($archivo.Nombre, [IO.Compression.CompressionLevel]::Optimal)
      $entrada.LastWriteTime = $fechaFija
      $entrada.ExternalAttributes = $permisosLectura

      $destino = $entrada.Open()
      $origen = [IO.File]::OpenRead($archivo.Ruta)

      try {
        $origen.CopyTo($destino)
      }
      finally {
        $origen.Dispose()
        $destino.Dispose()
      }
    }
  }
  finally {
    $zip.Dispose()
    $flujo.Dispose()
  }
}

# Empaqueta cada Lambda en una carpeta temporal (no en el repositorio) para
# que los node_modules de Linux no se mezclen con los tuyos.
# Los parámetros --os/--cpu/--libc obligan a npm a bajar los binarios de
# sharp para Linux x64, aunque se ejecute en Windows (camino del anexo).
function Comando-Construir {
  New-Item -ItemType Directory -Force -Path $script:carpetaPaquetes | Out-Null
  $temporal = Join-Path ([IO.Path]::GetTempPath()) "paquetes-lambda-$PID"

  foreach ($funcion in $script:funcionesLambda) {
    Escribir-Paso "Empaquetando $funcion"

    $origen = Join-Path $script:raizRepositorio "app/$funcion"
    $trabajo = Join-Path $temporal $funcion
    New-Item -ItemType Directory -Force -Path $trabajo | Out-Null

    Copy-Item (Join-Path $origen 'package.json'), (Join-Path $origen 'package-lock.json') $trabajo

    Push-Location $trabajo
    try {
      npm ci --omit=dev --no-audit --no-fund --os=linux --cpu=x64 --libc=glibc --loglevel=error
      Confirmar-ExitoComando "npm ci de $funcion"
    }
    finally {
      Pop-Location
    }

    # npm baja también la variante "musl" de sharp (para Alpine). Lambda
    # corre sobre Amazon Linux, que usa glibc: esa variante solo ocupa
    # espacio, así que se quita.
    Get-ChildItem (Join-Path $trabajo 'node_modules/@img') -Directory -Filter '*musl*' -ErrorAction SilentlyContinue |
      Remove-Item -Recurse -Force

    # El handler del diagrama es index.handler: los .mjs van en la raíz del zip.
    Get-ChildItem (Join-Path $origen 'src') -Filter '*.mjs' |
      Copy-Item -Destination $trabajo

    $rutaZip = Join-Path $script:carpetaPaquetes "$funcion.zip"
    Crear-ZipReproducible $trabajo $rutaZip

    $tamano = [math]::Round((Get-Item $rutaZip).Length / 1MB, 2)
    Escribir-Ok "$funcion.zip ($tamano MB)"
  }

  Remove-Item -Recurse -Force $temporal -ErrorAction SilentlyContinue
}

# Un zip vacío pasa la validación pero rompería un despliegue: aquí se
# comprueba que los paquetes sean reales antes de aplicar.
function Asegurar-PaquetesListos {
  foreach ($funcion in $script:funcionesLambda) {
    $ruta = Join-Path $script:carpetaPaquetes "$funcion.zip"

    if (-not (Test-Path $ruta) -or (Get-Item $ruta).Length -lt 10KB) {
      Escribir-Aviso 'Faltan los paquetes de las Lambdas; se construyen ahora.'
      Comando-Construir
      return
    }
  }
}

function Comando-Pruebas {
  foreach ($funcion in $script:funcionesLambda) {
    $carpeta = Join-Path $script:raizRepositorio "app/$funcion"

    # Mientras se construye el proyecto paso a paso, la Lambda puede no existir aún.
    if (-not (Test-Path (Join-Path $carpeta 'package.json'))) {
      Escribir-Aviso "app/$funcion todavía no existe; se omiten sus pruebas."
      continue
    }

    Escribir-Paso "Pruebas de $funcion"
    Push-Location $carpeta

    try {
      npm ci --no-audit --no-fund --loglevel=error
      Confirmar-ExitoComando "npm ci de $funcion"

      npm test
      Confirmar-ExitoComando "pruebas de $funcion"
    }
    finally {
      Pop-Location
    }
  }
}

# Lo mismo que revisa el pipeline en cada Pull Request, pero en tu equipo.
function Comando-Validar {
  $carpetaInfra = Join-Path $script:raizRepositorio 'infra'

  if (Test-Path $carpetaInfra) {
    Escribir-Paso 'Formato de Terraform'
    terraform fmt -check -recursive $carpetaInfra
    Confirmar-ExitoComando 'terraform fmt (ejecuta "terraform fmt -recursive infra" para corregir)'
    Escribir-Ok 'Formato correcto'
  }
  else {
    Escribir-Aviso 'La carpeta infra todavía no existe; se omite Terraform.'
  }

  # validate necesita que existan los zip; para validar sirven vacíos.
  New-Item -ItemType Directory -Force -Path $script:carpetaPaquetes | Out-Null

  foreach ($funcion in $script:funcionesLambda) {
    $ruta = Join-Path $script:carpetaPaquetes "$funcion.zip"

    if (-not (Test-Path $ruta)) {
      New-Item -ItemType File -Path $ruta | Out-Null
    }
  }

  foreach ($entorno in $script:entornosValidos) {
    $carpeta = Obtener-CarpetaEntorno $entorno

    if (-not (Test-Path (Join-Path $carpeta 'main.tf'))) {
      Escribir-Aviso "infra/entornos/$entorno todavía no existe; se omite."
      continue
    }

    Escribir-Paso "Validando $entorno"

    terraform "-chdir=$carpeta" init -backend=false -input=false | Out-Null
    Confirmar-ExitoComando "terraform init de $entorno"

    terraform "-chdir=$carpeta" validate
    Confirmar-ExitoComando "terraform validate de $entorno"
  }

  if ((Test-Path $carpetaInfra) -and (Get-Command tflint -ErrorAction SilentlyContinue)) {
    Escribir-Paso 'tflint (incluye la convención camelCase / snake_case)'

    $configuracion = Join-Path $script:raizRepositorio '.tflint.hcl'

    Push-Location $script:raizRepositorio
    try {
      tflint --init --config $configuracion | Out-Null
      tflint --recursive --config $configuracion
      Confirmar-ExitoComando 'tflint'
    }
    finally {
      Pop-Location
    }

    Escribir-Ok 'tflint sin problemas'
  }

  Comando-Pruebas
}