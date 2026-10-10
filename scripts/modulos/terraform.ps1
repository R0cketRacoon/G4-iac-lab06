# Comandos que usan Terraform: bootstrap, iniciar, plan, desplegar, salidas
# y destruir.

function Comando-Bootstrap([switch]$Destruir) {
  Exigir-CuentaCorrecta
  $carpeta = Join-Path $script:raizRepositorio 'infra/bootstrap'

  Escribir-Paso 'Inicializando el bootstrap (estado local en infra/bootstrap)'
  terraform "-chdir=$carpeta" init -input=false
  Confirmar-ExitoComando 'terraform init del bootstrap'

  if ($Destruir) {
    if (-not (Confirmar-Accion 'Se borrará el bucket con los estados de TODOS los entornos.' 'bootstrap')) {
      Escribir-Aviso 'Cancelado.'
      return
    }

    $evidencia = Join-Path $script:raizRepositorio 'docs/evidencias/destroy/terraform-destroy-bootstrap.txt'

    terraform "-chdir=$carpeta" apply -auto-approve -var='permitirDestruccionEstado=true'
    Confirmar-ExitoComando 'habilitar el borrado del bucket de estado'

    terraform "-chdir=$carpeta" destroy -auto-approve -no-color -var='permitirDestruccionEstado=true' 2>&1 |
      Tee-Object -FilePath $evidencia

    Confirmar-ExitoComando 'destruir el bootstrap'
    Escribir-Ok "Salida guardada en $evidencia"
    return
  }

  terraform "-chdir=$carpeta" apply
  Confirmar-ExitoComando 'terraform apply del bootstrap'

  $rol = terraform "-chdir=$carpeta" output -raw arnRolDespliegueGithub
  $bucket = terraform "-chdir=$carpeta" output -raw nombreBucketEstado

  Escribir-Paso 'Configura GitHub con estos valores (una sola vez)'
  Write-Host " gh variable set AWS_ROLE_ARN --body `"$rol`""
  Write-Host " gh variable set BUCKET_ESTADO --body `"$bucket`""
  Write-Host " gh variable set ID_CUENTA_AWS --body `"$($script:idCuentaAws)`""
  Write-Host " gh variable set REGION_AWS        --body `"$($script:regionAws)`""
  Escribir-Aviso 'Guarda una copia de infra/bootstrap/terraform.tfstate en un lugar seguro: no va a Git.'
}

# Conecta un entorno con el bucket de estado. Se repite sin problema.
function Comando-Iniciar([string]$entorno) {
  Validar-Entorno $entorno

  Escribir-Paso "Inicializando $entorno con el estado en s3://$($script:bucketEstado)"

  terraform "-chdir=$(Obtener-CarpetaEntorno $entorno)" init -reconfigure -input=false `
    "-backend-config=bucket=$($script:bucketEstado)" `
    "-backend-config=region=$($script:regionAws)" `
    "-backend-config=profile=$($script:perfilAws)"

  Confirmar-ExitoComando "terraform init de $entorno"
}

function Comando-Plan([string]$entorno) {
  Validar-Entorno $entorno
  Exigir-CuentaCorrecta
  Asegurar-PaquetesListos
  Comando-Iniciar $entorno

  Escribir-Paso "Plan de $entorno (no cambia nada en AWS)"

  terraform "-chdir=$(Obtener-CarpetaEntorno $entorno)" plan -input=false -out="plan-$entorno.tfplan"
  Confirmar-ExitoComando "terraform plan de $entorno"
}

function Comando-Desplegar([string]$entorno) {
  Comando-Plan $entorno

  if ($entorno -eq 'prod' -and -not (Confirmar-Accion 'Vas a aplicar cambios en PRODUCCIÓN.' 'prod')) {
    Escribir-Aviso 'Cancelado.'
    return
  }

  Escribir-Paso "Aplicando $entorno"

  $carpeta = Obtener-CarpetaEntorno $entorno

  terraform "-chdir=$carpeta" apply -input=false "plan-$entorno.tfplan"
  Confirmar-ExitoComando "terraform apply de $entorno"

  Comando-Salidas $entorno
}

function Comando-Salidas([string]$entorno) {
  Validar-Entorno $entorno

  Escribir-Paso "Datos de $entorno"

  terraform "-chdir=$(Obtener-CarpetaEntorno $entorno)" output
}

function Comando-Destruir([string]$entorno) {
  Validar-Entorno $entorno
  Exigir-CuentaCorrecta

  if (-not (Confirmar-Accion "Se van a BORRAR todos los recursos de $entorno." $entorno)) {
    Escribir-Aviso 'Cancelado.'
    return
  }

  # destroy también evalúa filebase64sha256: necesita los zip.
  Asegurar-PaquetesListos
  Comando-Iniciar $entorno

  $carpetaEvidencia = Join-Path $script:raizRepositorio 'docs/evidencias/destroy'
  New-Item -ItemType Directory -Force -Path $carpetaEvidencia | Out-Null
  $registro = Join-Path $carpetaEvidencia "terraform-destroy-$entorno.txt"

  Escribir-Paso "Destruyendo $entorno (las interfaces de red de Lambda tardan 20 a 40 minutos en liberarse)"

  terraform "-chdir=$(Obtener-CarpetaEntorno $entorno)" destroy -auto-approve -input=false -no-color 2>&1 |
    Tee-Object -FilePath $registro

  Confirmar-ExitoComando "terraform destroy de $entorno"
  Escribir-Ok "Salida guardada en $registro"

  Comando-VerificarDestruccion $entorno
}