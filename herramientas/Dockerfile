# syntax=docker/dockerfile:1

FROM node:20-bookworm-slim

# Con pipefail, si falla cualquier parte de una tubería (por ejemplo, la
# verificación del checksum de Terraform), el build se detiene.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Versiones fijas. Para actualizar al equipo entero se cambia el número aquí
# y se hace un commit "build(herramientas): actualizar terraform a x.y.z".
ARG VERSION_TERRAFORM=1.11.4
ARG VERSION_TFLINT=0.55.1

ENV DEBIAN_FRONTEND=noninteractive \
    AWS_PAGER="" \
    TF_PLUGIN_CACHE_DIR=/cache/terraform \
    TF_IN_AUTOMATION=true \
    EN_CONTENEDOR=true

# Paquetes base: git para commits desde el Dev Container, zip/unzip para los
# paquetes, curl para descargas y pruebas del API, jq para leer JSON.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl git unzip zip jq less gnupg \
 && rm -rf /var/lib/apt/lists/*

# PowerShell 7: los scripts del proyecto son .ps1 y funcionan igual en
# Windows y aquí dentro.
RUN curl -fsSL -o /tmp/ms.deb https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb \
 && dpkg -i /tmp/ms.deb && rm /tmp/ms.deb \
 && apt-get update && apt-get install -y --no-install-recommends powershell \
 && rm -rf /var/lib/apt/lists/*

# Terraform, verificando su suma SHA256 contra la publicada por HashiCorp.
RUN cd /tmp \
 && curl -fsSLO "https://releases.hashicorp.com/terraform/${VERSION_TERRAFORM}/terraform_${VERSION_TERRAFORM}_linux_amd64.zip" \
 && curl -fsSLO "https://releases.hashicorp.com/terraform/${VERSION_TERRAFORM}/terraform_${VERSION_TERRAFORM}_SHA256SUMS" \
 && grep "linux_amd64.zip" "terraform_${VERSION_TERRAFORM}_SHA256SUMS" | sha256sum -c - \
 && unzip -q "terraform_${VERSION_TERRAFORM}_linux_amd64.zip" -d /usr/local/bin \
 && rm -f /tmp/terraform_*

# AWS CLI v2. Se instala la versión vigente: la CLI es compatible hacia atrás
# y necesitamos el inicio de sesión con --use-device-code (desde la 2.22).
RUN cd /tmp \
 && curl -fsSL -o awscli.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip \
 && unzip -q awscli.zip && ./aws/install && rm -rf aws awscli.zip

# tflint con el plugin de AWS ya descargado, para no depender de la API de
# GitHub cada vez que alguien valida.
COPY .tflint.hcl /tmp/.tflint.hcl
RUN cd /tmp \
 && curl -fsSL -o tflint.zip "https://github.com/terraform-linters/tflint/releases/download/v${VERSION_TFLINT}/tflint_linux_amd64.zip" \
 && unzip -q tflint.zip -d /usr/local/bin && rm tflint.zip \
 && tflint --init --config /tmp/.tflint.hcl

# El repositorio se monta desde Windows con otro dueño; sin esto, Git se
# niega a trabajar ("dubious ownership").
RUN git config --system --add safe.directory /workspace \
 && mkdir -p /cache/terraform

# Atajo "proyecto" en la terminal de PowerShell del Dev Container.
COPY herramientas/perfil.ps1 /root/.config/powershell/Microsoft.PowerShell_profile.ps1

WORKDIR /workspace
