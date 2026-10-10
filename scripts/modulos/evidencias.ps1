# "proyecto evidencias <entorno>" y "proyecto verificar-destruccion <entorno>"
# Dejan en docs/evidencias un registro en texto de lo que existe en AWS.

function Comando-Evidencias([string]$entorno) {
  Validar-Entorno $entorno
  Exigir-CuentaCorrecta

  $carpeta = Join-Path $script:raizRepositorio "docs/evidencias/$entorno"
  New-Item -ItemType Directory -Force -Path $carpeta | Out-Null

  $archivo = Join-Path $carpeta "evidencia-cli-$entorno.txt"
  $nombreBase = "$($script:nombreProyecto)-$entorno"
  $carpetaEntorno = Obtener-CarpetaEntorno $entorno

  $secciones = [ordered]@{
    'Identidad y cuenta AWS' = {
      aws sts get-caller-identity --output table
    }

    'Outputs de Terraform' = {
      terraform "-chdir=$carpetaEntorno" output
    }

    'Recursos en el estado' = {
      terraform "-chdir=$carpetaEntorno" state list
    }

    'VPC' = {
      aws ec2 describe-vpcs `
        --filters "Name=tag:Entorno,Values=$entorno" "Name=tag:Proyecto,Values=$($script:nombreProyecto)" `
        --query 'Vpcs[].{Id:VpcId,Cidr:CidrBlock}' `
        --output table
    }

    'Subredes' = {
      aws ec2 describe-subnets `
        --filters "Name=tag:Entorno,Values=$entorno" "Name=tag:Proyecto,Values=$($script:nombreProyecto)" `
        --query 'Subnets[].{Nombre:Tags[?Key==`Name`]|[0].Value,Cidr:CidrBlock,Zona:AvailabilityZone}' `
        --output table
    }

    'NAT Gateways' = {
      aws ec2 describe-nat-gateways `
        --filter "Name=tag:Entorno,Values=$entorno" `
        --query 'NatGateways[].{Id:NatGatewayId,Estado:State,Subred:SubnetId}' `
        --output table
    }

    'VPC Endpoints' = {
      aws ec2 describe-vpc-endpoints `
        --filters "Name=tag:Entorno,Values=$entorno" `
        --query 'VpcEndpoints[].{Servicio:ServiceName,Tipo:VpcEndpointType,Estado:State}' `
        --output table
    }

    'Lambdas' = {
      aws lambda list-functions `
        --query "Functions[?starts_with(FunctionName,'$nombreBase')].{Nombre:FunctionName,Runtime:Runtime,Memoria:MemorySize,Timeout:Timeout}" `
        --output table
    }

    'Colas SQS' = {
      aws sqs list-queues `
        --queue-name-prefix $nombreBase `
        --output table
    }

    'Objetos procesados en S3' = {
      aws s3 ls "s3://$(Obtener-SalidaTerraform $entorno 'nombreBucketImagenes')/processed/"
    }

    'Alarmas' = {
      aws cloudwatch describe-alarms `
        --alarm-name-prefix $nombreBase `
        --query 'MetricAlarms[].{Nombre:AlarmName,Estado:StateValue}' `
        --output table
    }
  }

  Set-Content `
    -Path $archivo `
    -Value "Evidencia de $entorno generada el $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" `
    -Encoding utf8

  foreach ($titulo in $secciones.Keys) {
    Add-Content -Path $archivo -Value "`n### $titulo`n" -Encoding utf8
    (& $secciones[$titulo] 2>&1 | Out-String) |
      Add-Content -Path $archivo -Encoding utf8
  }

  Escribir-Ok "Evidencia guardada en $archivo"
}

function Comando-VerificarDestruccion([string]$entorno) {
  Validar-Entorno $entorno
  Exigir-CuentaCorrecta

  $nombreBase = "$($script:nombreProyecto)-$entorno"
  $proyecto = $script:nombreProyecto
  $archivo = Join-Path $script:raizRepositorio "docs/evidencias/destroy/verificacion-$entorno.txt"

  New-Item -ItemType Directory -Force -Path (Split-Path $archivo) | Out-Null

  $restos = @()

  $revisiones = [ordered]@{
    'Recursos etiquetados' = {
      aws resourcegroupstaggingapi get-resources `
        --tag-filters "Key=Proyecto,Values=$proyecto" "Key=Entorno,Values=$entorno" `
        --query 'ResourceTagMappingList[].ResourceARN' `
        --output json
    }

    'VPC' = {
      aws ec2 describe-vpcs `
        --filters "Name=tag:Entorno,Values=$entorno" "Name=tag:Proyecto,Values=$proyecto" `
        --query 'Vpcs[].VpcId' `
        --output json
    }

    'NAT Gateways activos' = {
      aws ec2 describe-nat-gateways `
        --filter "Name=tag:Entorno,Values=$entorno" 'Name=state,Values=pending,available' `
        --query 'NatGateways[].NatGatewayId' `
        --output json
    }

    'IPs elásticas' = {
      aws ec2 describe-addresses `
        --filters "Name=tag:Entorno,Values=$entorno" `
        --query 'Addresses[].PublicIp' `
        --output json
    }

    'Lambdas' = {
      aws lambda list-functions `
        --query "Functions[?starts_with(FunctionName,'$nombreBase')].FunctionName" `
        --output json
    }

    'Buckets' = {
      aws s3api list-buckets `
        --query "Buckets[?starts_with(Name,'$nombreBase')].Name" `
        --output json
    }

    'Log groups' = {
      aws logs describe-log-groups `
        --log-group-name-prefix "/aws/lambda/$nombreBase" `
        --query 'logGroups[].logGroupName' `
        --output json
    }
  }

  Escribir-Paso "Buscando restos de $entorno en la cuenta $($script:idCuentaAws)"

  foreach ($titulo in $revisiones.Keys) {
    $resultado = (& $revisiones[$titulo] | Out-String).Trim()

    if ($resultado -and $resultado -ne '[]' -and $resultado -ne 'null') {
      $restos += "${titulo}: $resultado"
      Escribir-Aviso "${titulo}: todavía existe algo"
    }
    else {
      Escribir-Ok "${titulo}: nada"
    }
  }

  $resumen = if ($restos.Count -eq 0) {
    "Entorno $entorno destruido por completo en la cuenta $($script:idCuentaAws). No se encontraron recursos."
  }
  else {
    $restos -join "`n"
  }

  Set-Content `
    -Path $archivo `
    -Value "Verificación del $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n$resumen" `
    -Encoding utf8

  Escribir-Paso $resumen
}