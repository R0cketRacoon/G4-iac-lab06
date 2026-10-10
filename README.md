# AWS + Lambda Integration
## Procesador de Imágenes

**Grupo 4 (Integrantes):**
- Piero Cardenas, Julian
- Mudarra Mauricio, Miller
- Colona Chávez, Fabricio
- Polo Lujan, Willian
- Gutiérrez Gamboa Fabrizzio Martín

**Docente:** Leturia Rodríguez, Walter Iván


## Descripción

Procesador de imágenes serverless en AWS, construido con Terraform siguiendo
exactamente el diagrama [`docs/architecture.mermaid`](docs/architecture.mermaid).
El cliente sube una imagen y, unos segundos después, obtiene una versión
circular de 40x40 píxeles en PNG con fondo transparente. Se despliega en tres
entornos (dev, qa y prod) dentro de la cuenta configurada en el archivo `.env`.


## Inicio

Se necesitó del uso de **Git**, del entorno de desarrollo **VS Code** (con la extensión Dev Containers) y de **Docker Desktop**. Terraform, AWS CLI, Node.js, tflint y PowerShell ya vienen dentro de un contenedor preparado para el proyecto.

### ¿Para qué sirve Docker Desktop?

Su función es ejecutar en Windows el contenedor de herraminetas del proyecto.

### ¿Para qué sirve la extensión Dev Containers?

La extensión **Dev Containers** de VS Code  abre el proyecto **dentro** del contenedor. Al abrir la carpeta, VS Code ofrece **Reopen in Container**. Desde ese momento:

- La terminal integrada es PowerShell 7 dentro del contenedor, con todas las herramientas listas.

- Las extensiones de Terraform, PowerShell, GitHub Actions y Conventional Commits se instalan solas.

- La validación de commits (commitlint) queda activa sin configurar nada.

La configuración está en `.devcontainer/devcontainer.json` y `docker-compose.yml`.

### ¿Afecta lo que se despliega en AWS o su costo?

No, debido a que el contenedor corre en nuestra laptop u ordenador de escritorio y desde ahí llama a la API de AWS, igual que si Terraform estuviera instalado en Windows. Los recursos creados, el estado de Terraform y el costo en AWS son los mismo.

Tampoco cambia la forma de conectarnos, ya que el contendor monta nuestra carpeta `.aws` de Windows y usa nuestro **perfil de AWS CLI**. No se guardan llaves de acceso en ningún archivo.


## Arquitectura

### Original

```mermaid
%%{
  init: {
    "theme": "base",
    "themeVariables": {
      "primaryColor": "#1e293b",
      "primaryTextColor": "#f8fafc",
      "primaryBorderColor": "#334155",
      "lineColor": "#94a3b8",
      "secondaryColor": "#0f172a",
      "tertiaryColor": "#1e293b",
      "background": "#0f172a",
      "mainBkg": "#1e293b",
      "nodeBorder": "#475569",
      "clusterBkg": "#0f172a",
      "titleColor": "#f8fafc",
      "edgeLabelBackground": "#1e293b",
      "fontFamily": "monospace"
    },
    "flowchart": { "curve": "basis", "padding": 20 }
  }
}%%

flowchart TD

  %% ── INTERNET ──────────────────────────────────────────────────────────────
  subgraph INTERNET["Internet"]
    CLIENT["Client\n---\nPOST /upload\nmultipart/form-data or JSON+base64\nMax size: 10 MB\nAllowed: jpg, png, gif, webp"]
  end

  %% ── AWS ACCOUNT ───────────────────────────────────────────────────────────
  subgraph AWS["AWS Account — Region: us-east-1"]

    %% ── EDGE SERVICES ─────────────────────────────────────────────────────
    subgraph EDGE["AWS Managed Edge Services — outside VPC"]

      APIGW["API Gateway HTTP API v2\n---\nRoute: POST /upload\nProtocol: HTTPS, TLS 1.2+\nPayload format: 2.0\nCORS: enabled\nStage: default, auto-deploy\nThrottling: 10,000 rps\nAccess logs to CloudWatch"]

      subgraph S3_SVC["Amazon S3 — Bucket: image-processor-env-images-suffix"]
        S3_UPLOADS["uploads/ prefix\n---\nStores: original images\nSSE: AES-256\nVersioning: enabled\nLifecycle: expire after 30 days\nAccess: fully private\nOn ObjectCreated fires SQS notification"]
        S3_PROCESSED["processed/ prefix\n---\nStores: cropped circular PNGs\nSSE: AES-256\nOutput: 40x40 px, PNG, transparent bg\nLifecycle: expire after 90 days\nAccess: fully private"]
      end

      subgraph SQS_SVC["Amazon SQS"]
        SQS_QUEUE["Main Queue\n---\nName: image-processor-env-image-queue\nType: Standard\nVisibility timeout: 360 s (6x Lambda timeout)\nRetention: 1 day\nLong polling: 20 s\nMax receives before DLQ: 3"]
        SQS_DLQ["Dead-Letter Queue\n---\nName: image-processor-env-image-dlq\nRetention: 14 days\nCloudWatch alarm on any visible message"]
      end

    end

    %% ── VPC ────────────────────────────────────────────────────────────────
    subgraph VPC["VPC — CIDR: 10.0.0.0/16 — DNS resolution and hostnames enabled"]

      IGW["Internet Gateway\n---\nAttached to VPC\nEntry point for inbound\npublic traffic"]

      %% ── PUBLIC SUBNETS ──────────────────────────────────────────────────
      subgraph PUB_A["Public Subnet AZ-a — 10.0.1.0/24 — Route 0.0.0.0/0 to IGW"]
        NAT_A["NAT Gateway A\n---\nElastic IP: allocated\nRoutes outbound traffic\nfor private subnet AZ-a"]
      end

      subgraph PUB_B["Public Subnet AZ-b — 10.0.2.0/24 — Route 0.0.0.0/0 to IGW"]
        NAT_B["NAT Gateway B\n---\nElastic IP: allocated\nRoutes outbound traffic\nfor private subnet AZ-b\nHigh-availability fallback"]
      end

      %% ── PRIVATE SUBNETS ─────────────────────────────────────────────────
      subgraph PRIV_A["Private Subnet AZ-a — 10.0.11.0/24 — Route 0.0.0.0/0 to NAT-A"]

        subgraph SG_UPLOAD["SG: sg-upload-lambda | Inbound: none | Outbound: TCP 443 to vpce-s3 and vpce-sqs"]
          LAMBDA_UPLOAD["upload-lambda\n---\nRuntime: nodejs20.x\nMemory: 256 MB — Timeout: 30 s\nHandler: index.handler\nEnv: S3_BUCKET, UPLOAD_PREFIX\nDeps: @aws-sdk/client-s3, busboy, uuid\nIAM: s3:PutObject on uploads/ only\nLogs: /aws/lambda/...-upload"]
        end

        subgraph SG_CROP["SG: sg-crop-lambda | Inbound: none | Outbound: TCP 443 to vpce-s3 and vpce-sqs"]
          LAMBDA_CROP["crop-lambda\n---\nRuntime: nodejs20.x\nMemory: 512 MB — Timeout: 60 s\nHandler: index.handler\nEnv: S3_BUCKET, PROCESSED_PREFIX\nDeps: @aws-sdk/client-s3, sharp 0.33\nCrop: resize 40x40 cover, SVG circle mask\nOutput: PNG with transparent alpha\nIAM: s3:GetObject uploads/, s3:PutObject processed/\nSQS: ReceiveMessage, DeleteMessage, ChangeVisibility\nLogs: /aws/lambda/...-crop"]
        end

      end

      subgraph PRIV_B["Private Subnet AZ-b — 10.0.12.0/24 — Route 0.0.0.0/0 to NAT-B"]
        LAMBDA_UPLOAD_B["upload-lambda replica AZ-b\n---\nIdentical config to AZ-a\nLambda auto-distributes ENIs\nacross both private subnets"]
        LAMBDA_CROP_B["crop-lambda replica AZ-b\n---\nIdentical config to AZ-a\nLambda auto-distributes ENIs\nacross both private subnets"]
      end

      %% ── VPC ENDPOINTS ───────────────────────────────────────────────────
      subgraph VPCE["VPC Endpoints — traffic stays on AWS backbone, never hits public internet"]

        VPCE_S3["S3 Gateway Endpoint\n---\nType: Gateway — free, no ENI\nService: com.amazonaws.us-east-1.s3\nInjected into private subnet route tables\nPolicy: s3:GetObject and s3:PutObject\nscoped to the images bucket only"]

        VPCE_SQS["SQS Interface Endpoint\n---\nType: Interface — ENI per AZ\nService: com.amazonaws.us-east-1.sqs\nPrivate DNS: enabled\nDeployed in: priv-a, priv-b\nSG: sg-vpce-sqs\nInbound TCP 443 from sg-upload-lambda\nInbound TCP 443 from sg-crop-lambda"]

      end

    end

    %% ── IAM ───────────────────────────────────────────────────────────────
    subgraph IAM["IAM — Least-Privilege Roles"]
      ROLE_UPLOAD["Role: upload-lambda-role\n---\nAWSLambdaBasicExecutionRole\nAWSLambdaVPCAccessExecutionRole\ns3:PutObject scoped to uploads/ only"]
      ROLE_CROP["Role: crop-lambda-role\n---\nAWSLambdaBasicExecutionRole\nAWSLambdaVPCAccessExecutionRole\ns3:GetObject on uploads/\ns3:PutObject on processed/\nsqs: ReceiveMessage, DeleteMessage\nGetQueueAttributes, ChangeMessageVisibility"]
    end

    %% ── OBSERVABILITY ─────────────────────────────────────────────────────
    subgraph OBS["Observability — CloudWatch"]
      CW_UPLOAD["Log Group\n/aws/lambda/...-upload\nRetention: 14 days"]
      CW_CROP["Log Group\n/aws/lambda/...-crop\nRetention: 14 days"]
      CW_APIGW["Log Group\n/aws/apigateway/...\nRetention: 14 days\nFormat: JSON access log"]
      CW_ALARM["CloudWatch Alarm: dlq-messages-alarm\n---\nMetric: ApproximateNumberOfMessagesVisible\nNamespace: AWS/SQS\nPeriod: 60 s — Threshold: above 0\nAction: notify via SNS topic"]
    end

  end

  %% ── DATA FLOW ─────────────────────────────────────────────────────────────

  CLIENT -->|"1 - HTTPS POST /upload, TLS 1.2+, max 10 MB"| APIGW
  APIGW -->|"2 - Lambda Proxy Invoke, Payload 2.0"| LAMBDA_UPLOAD
  APIGW -->|"2 - replica invoke"| LAMBDA_UPLOAD_B

  LAMBDA_UPLOAD -->|"3 - s3:PutObject via S3 Gateway Endpoint"| VPCE_S3
  LAMBDA_UPLOAD_B -->|"3 - replica"| VPCE_S3
  VPCE_S3 -->|"writes to uploads/"| S3_UPLOADS

  S3_UPLOADS -->|"4 - S3 Event Notification, ObjectCreated, AWS internal network"| SQS_QUEUE

  SQS_QUEUE -->|"5 - ESM trigger, batch size 5, ReportBatchItemFailures"| LAMBDA_CROP
  SQS_QUEUE -->|"5 - replica"| LAMBDA_CROP_B

  LAMBDA_CROP -->|"6 - s3:GetObject via S3 Gateway Endpoint"| VPCE_S3
  LAMBDA_CROP_B -->|"6 - replica"| VPCE_S3
  S3_UPLOADS -->|"reads from"| VPCE_S3

  LAMBDA_CROP -->|"7 - s3:PutObject, name_circular.png, 40x40 PNG"| VPCE_S3
  LAMBDA_CROP_B -->|"7 - replica"| VPCE_S3
  VPCE_S3 -->|"writes to processed/"| S3_PROCESSED

  LAMBDA_CROP -->|"sqs:ReceiveMessage and DeleteMessage via Interface Endpoint"| VPCE_SQS
  LAMBDA_CROP_B -->|"same"| VPCE_SQS
  VPCE_SQS -->|"connected to"| SQS_QUEUE

  SQS_QUEUE -->|"after 3 failed receives"| SQS_DLQ
  SQS_DLQ -.->|"triggers alarm"| CW_ALARM

  LAMBDA_UPLOAD -.->|"logs"| CW_UPLOAD
  LAMBDA_CROP -.->|"logs"| CW_CROP
  APIGW -.->|"access logs"| CW_APIGW

  LAMBDA_UPLOAD -.->|"assumes"| ROLE_UPLOAD
  LAMBDA_CROP -.->|"assumes"| ROLE_CROP

  IGW -.- NAT_A
  IGW -.- NAT_B

  %% ── STYLES ────────────────────────────────────────────────────────────────

  classDef clientNode fill:#0f172a,stroke:#6366f1,stroke-width:2px,color:#e0e7ff
  classDef edgeNode fill:#1e3a5f,stroke:#3b82f6,stroke-width:2px,color:#bfdbfe
  classDef lambdaNode fill:#14532d,stroke:#22c55e,stroke-width:2px,color:#dcfce7
  classDef s3Node fill:#3b1f0f,stroke:#f97316,stroke-width:2px,color:#ffedd5
  classDef sqsNode fill:#4a1d96,stroke:#a78bfa,stroke-width:2px,color:#ede9fe
  classDef iamNode fill:#1f2937,stroke:#facc15,stroke-width:2px,color:#fef9c3
  classDef obsNode fill:#1f2937,stroke:#94a3b8,stroke-width:2px,color:#e2e8f0
  classDef vpceNode fill:#0c2340,stroke:#38bdf8,stroke-width:2px,color:#bae6fd
  classDef natNode fill:#1c1917,stroke:#84cc16,stroke-width:2px,color:#d9f99d

  class CLIENT clientNode
  class APIGW,IGW edgeNode
  class LAMBDA_UPLOAD,LAMBDA_CROP,LAMBDA_UPLOAD_B,LAMBDA_CROP_B lambdaNode
  class S3_UPLOADS,S3_PROCESSED s3Node
  class SQS_QUEUE,SQS_DLQ sqsNode
  class ROLE_UPLOAD,ROLE_CROP iamNode
  class CW_UPLOAD,CW_CROP,CW_APIGW,CW_ALARM obsNode
  class VPCE_S3,VPCE_SQS vpceNode
  class NAT_A,NAT_B natNode
  ```


### Propuesta

```mermaid
%% Propuesta 2: el diagrama original se respeta; [NUEVO] marca lo agregado
%% para que funcione o para cumplir los 10 MB.
flowchart TD

  CLIENT["Cliente<br/>POST /upload hasta 4 MB: multipart o JSON+base64<br/>POST /upload-url hasta 10 MB [NUEVO]<br/>jpg, png, gif, webp"]

  subgraph AWS["Cuenta AWS del .env - us-east-1 - un despliegue por entorno: dev, qa, prod"]

    subgraph EDGE["Servicios administrados - fuera de la VPC"]
      APIGW["API Gateway HTTP API v2<br/>POST /upload y POST /upload-url<br/>TLS 1.2+, payload 2.0, CORS<br/>Stage default auto-deploy<br/>Throttling 10.000 rps, access logs"]
      S3["S3: image-processor-ENV-images-SUFIJO<br/>uploads/ 30 días - processed/ 90 días<br/>SSE AES-256, versionado, privado"]
      SQS["SQS image-queue<br/>Standard, visibilidad 360 s<br/>retención 1 día, long polling 20 s<br/>3 recepciones antes de la DLQ"]
      DLQ["SQS image-dlq<br/>retención 14 días"]
      SNS["SNS tópico de alertas [NUEVO]"]
    end

    subgraph VPC["VPC 10.0.0.0/16 - DNS activado"]
      IGW["Internet Gateway"]
      subgraph PUB["Subredes públicas 10.0.1.0/24 y 10.0.2.0/24"]
        NATA["NAT Gateway A + EIP"]
        NATB["NAT Gateway B + EIP"]
      end
      subgraph PRIV["Subredes privadas 10.0.11.0/24 y 10.0.12.0/24"]
        UPLOAD["upload-lambda nodejs20.x<br/>256 MB, 30 s<br/>sg-upload-lambda: 443 a vpce-s3 y vpce-sqs<br/>una función, ENIs en ambas zonas"]
        CROP["crop-lambda nodejs20.x<br/>512 MB, 60 s, sharp 0.33<br/>40x40 PNG circular<br/>sg-crop-lambda: 443 a vpce-s3 y vpce-sqs"]
      end
      VPCES3["S3 Gateway Endpoint<br/>política: solo el bucket"]
      VPCESQS["SQS Interface Endpoint<br/>DNS privado, sg-vpce-sqs"]
    end

    subgraph IAM["IAM mínimo privilegio"]
      ROLES["upload-lambda-role · crop-lambda-role"]
    end

    subgraph OBS["CloudWatch"]
      LOGS["Log groups 14 días"]
      ALARMA["dlq-messages-alarm"]
    end
  end

  subgraph EQUIPO["Equipo y entrega [NUEVO]"]
    HERR["Contenedor de herramientas<br/>Dev Containers + .env"]
    GH["GitHub Actions + OIDC"]
  end

  CLIENT -->|"1 - HTTPS POST /upload"| APIGW
  APIGW -->|"2 - Lambda proxy, payload 2.0"| UPLOAD
  UPLOAD -->|"3 - PutObject"| VPCES3
  CLIENT -.->|"3b - POST firmado"| S3
  VPCES3 --> S3
  S3 -->|"4 - ObjectCreated en uploads/"| SQS
  SQS -->|"5 - lotes de 5"| CROP
  CROP -->|"6 y 7 - Get uploads, Put processed"| VPCES3
  CROP --- VPCESQS
  VPCESQS --- SQS
  SQS -->|"3 fallos"| DLQ
  DLQ -.-> ALARMA
  ALARMA --> SNS
  IGW --- NATA
  IGW --- NATB
  UPLOAD -.-> ROLES
  CROP -.-> LOGS
  HERR --> GH
  GH -.->|"terraform apply"| AWS
```



## Configuración (.env)

| Clave | Para qué |
|---|---|
| `ID_CUENTA_AWS` | Cuenta donde se permite desplegar. Terraform se niega a usar otra. |
| `REGION_AWS` | Región (us-east-1, como el diagrama) |
| `PERFIL_AWS` | Perfil de AWS SSO de cada integrante |
| `ORGANIZACION_GITHUB`, `REPOSITORIO_GITHUB` | Para el rol OIDC de GitHub Actions |
| `CORREO_ALERTAS` | Destino de la alarma de la DLQ |
| `BUCKET_ESTADO` | Opcional: nombre del bucket del estado de Terraform |

El `.env` **nunca** se sube a Git. En GitHub Actions, estos valores son
variables del repositorio o de cada environment.
