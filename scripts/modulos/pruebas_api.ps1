# "proyecto probar <entorno> [-Caso ...]"
# Prueba el flujo completo del diagrama: subida, evento, recorte y resultado.

function Comando-Probar([string]$entorno, [string]$caso = 'todos') {
  Validar-Entorno $entorno
  Exigir-CuentaCorrecta

  $script:urlApi = Obtener-SalidaTerraform $entorno 'urlApi'
  $script:bucketImagenes = Obtener-SalidaTerraform $entorno 'nombreBucketImagenes'
  $script:curl = if ($IsWindows) { 'curl.exe' } else { 'curl' }
  $script:carpetaImagenes = Join-Path $script:raizRepositorio 'pruebas/imagenes'
  $script:carpetaResultados = Join-Path $script:raizRepositorio "pruebas/resultados/$entorno"

  New-Item -ItemType Directory -Force -Path $script:carpetaResultados | Out-Null

  Escribir-Paso "API: $($script:urlApi)"
  Escribir-Paso "Bucket: $($script:bucketImagenes)"

  switch ($caso) {
    'directo'    { Probar-SubidaMultipart }
    'json'       { Probar-SubidaJson }
    'prefirmada' { Probar-SubidaPrefirmada }
    'corrupto'   { Probar-ArchivoCorrupto $entorno }
    'todos'      { Probar-SubidaMultipart; Probar-SubidaJson; Probar-SubidaPrefirmada }
    default      { throw 'Caso no válido. Usa: directo, json, prefirmada, corrupto o todos.' }
  }
}

# Espera hasta 60 s a que aparezca la imagen circular y la descarga.
function Esperar-ImagenProcesada([string]$claveProcesada) {
  Write-Host " Esperando $claveProcesada " -NoNewline

  for ($intento = 0; $intento -lt 30; $intento++) {
    aws s3api head-object --bucket $script:bucketImagenes --key $claveProcesada 2>$null | Out-Null

    if ($LASTEXITCODE -eq 0) {
      Write-Host ''

      $destino = Join-Path $script:carpetaResultados (Split-Path $claveProcesada -Leaf)

      aws s3 cp "s3://$($script:bucketImagenes)/$claveProcesada" $destino --only-show-errors

      Escribir-Ok "Lista y descargada en $destino"
      return
    }

    Write-Host '.' -NoNewline
    Start-Sleep -Seconds 2
  }

  Write-Host ''
  Escribir-Aviso 'No apareció en 60 s. Revisa los logs de la Lambda de recorte en CloudWatch.'
}

# Paso 1 del diagrama con multipart/form-data.
function Probar-SubidaMultipart {
  Escribir-Paso 'Caso 1: POST /upload con multipart/form-data (paisaje.jpg)'

  $respuesta = & $script:curl --silent --show-error -X POST "$($script:urlApi)/upload" `
    -F "file=@$(Join-Path $script:carpetaImagenes 'paisaje.jpg')"

  Write-Host " $respuesta"

  $datos = $respuesta | ConvertFrom-Json

  if ($datos.claveProcesada) {
    Esperar-ImagenProcesada $datos.claveProcesada
  }
}

# Paso 1 del diagrama con JSON + base64.
function Probar-SubidaJson {
  Escribir-Paso 'Caso 2: POST /upload con JSON + base64 (logo.png)'

  $base64 = [Convert]::ToBase64String(
    [IO.File]::ReadAllBytes((Join-Path $script:carpetaImagenes 'logo.png'))
  )

  $cuerpo = @{
    fileName = 'logo.png'
    data = $base64
  } | ConvertTo-Json -Compress

  $datos = Invoke-RestMethod `
    -Method Post `
    -Uri "$($script:urlApi)/upload" `
    -ContentType 'application/json' `
    -Body $cuerpo

  Write-Host " $($datos | ConvertTo-Json -Compress)"

  Esperar-ImagenProcesada $datos.claveProcesada
}

function Subir-ConFormularioFirmado([string]$rutaArchivo, [string]$nombreDeclarado) {
  $tamano = (Get-Item $rutaArchivo).Length

  $cuerpo = @{
    fileName = $nombreDeclarado
    sizeBytes = $tamano
  } | ConvertTo-Json -Compress

  $datos = Invoke-RestMethod `
    -Method Post `
    -Uri "$($script:urlApi)/upload-url" `
    -ContentType 'application/json' `
    -Body $cuerpo

  Write-Host " Formulario recibido para $($datos.clave)"

  # S3 exige todos los campos firmados primero y el archivo al final.
  $argumentos = @(
    '--silent',
    '--show-error',
    '--fail-with-body',
    '-X',
    'POST',
    $datos.url
  )

  foreach ($campo in $datos.campos.PSObject.Properties) {
    $argumentos += @(
      '--form-string',
      "$($campo.Name)=$($campo.Value)"
    )
  }

  $argumentos += @('-F', "file=@$rutaArchivo")

  & $script:curl @argumentos

  Confirmar-ExitoComando 'subir el archivo a S3 con el formulario firmado'

  Escribir-Ok "Subido directo a S3 ($([math]::Round($tamano / 1MB, 2)) MB)"

  return $datos
}

function Probar-SubidaPrefirmada {
  Escribir-Paso 'Caso 3: imagen de ~6 MB con formulario firmado (POST /upload-url)'

  $datos = Subir-ConFormularioFirmado `
    (Join-Path $script:carpetaImagenes 'grande-6mb.png') `
    'grande-6mb.png'

  Esperar-ImagenProcesada $datos.claveProcesada
}

function Probar-ArchivoCorrupto([string]$entorno) {
  Escribir-Paso 'Caso 4: archivo falso para comprobar los 3 intentos, la DLQ y la alarma'

  Subir-ConFormularioFirmado `
    (Join-Path $script:carpetaImagenes 'archivo-corrupto.png') `
    'archivo-corrupto.png' | Out-Null

  Escribir-Aviso 'La Lambda fallará 3 veces (una cada 6 minutos por el visibility timeout de 360 s).'
  Escribir-Aviso 'En unos 20 minutos el mensaje llega a la DLQ y la alarma pasa a "In alarm".'

  Escribir-Aviso "Para revisarla: aws sqs get-queue-attributes --queue-url $(Obtener-SalidaTerraform $entorno 'urlColaFallidos') --attribute-names ApproximateNumberOfMessages"
}