// Lee un cuerpo multipart/form-data que llega desde API Gateway y
// devuelve el primer archivo que encuentre. Usamos busboy porque procesa
// el contenido por partes y respeta el límite de tamaño sin cargar
// basura de más en memoria.
import Busboy from 'busboy';

export class ErrorDeCarga extends Error {
  constructor(mensaje, codigoHttp = 400) {
    super(mensaje);
    this.codigoHttp = codigoHttp;
  }
}

export function leerArchivoMultipart(cuerpo, tipoContenido, tamanoMaximoBytes) {
  return new Promise((resolver, rechazar) => {
    let lector;
    try {
      lector = Busboy({
        headers: { 'content-type': tipoContenido },
        limits: { files: 1, fileSize: tamanoMaximoBytes },
      });
    } catch {
      rechazar(new ErrorDeCarga('El cuerpo multipart no tiene un formato válido.'));
      return;
    }

    let archivoEncontrado = null;
    let superoLimite = false;

    lector.on('file', (_campo, flujo, info) => {
      const pedazos = [];
      flujo.on('data', (pedazo) => pedazos.push(pedazo));
      flujo.on('limit', () => {
        superoLimite = true;
        flujo.resume();
      });
      flujo.on('end', () => {
        archivoEncontrado = {
          nombreArchivo: info.filename,
          tipoDeclarado: info.mimeType,
          contenido: Buffer.concat(pedazos),
        };
      });
    });

    lector.on('error', () => rechazar(new ErrorDeCarga('No se pudo leer el formulario enviado.')));

    lector.on('close', () => {
      if (superoLimite) {
        rechazar(new ErrorDeCarga('La imagen supera el tamaño permitido para esta ruta.', 413));
        return;
      }
      if (!archivoEncontrado || archivoEncontrado.contenido.length === 0) {
        rechazar(new ErrorDeCarga('No llegó ningún archivo en el formulario.'));
        return;
      }
      resolver(archivoEncontrado);
    });

    lector.end(cuerpo);
  });
}