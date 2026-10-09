# Grupo 4 - Procesador de Imágenes

**Integrantes:**
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


**Repositorio:** `https://github.com/R0cketRacoon/G4-iac-lab06`

**API dev:** ``

**API qa:** ``

**Cuenta AWS** ``


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


