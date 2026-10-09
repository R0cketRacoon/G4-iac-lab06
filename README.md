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
