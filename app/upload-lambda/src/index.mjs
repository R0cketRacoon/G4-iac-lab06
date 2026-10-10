// Lambda de carga.
//
// Atiende dos rutas del HTTP API:
//   POST /upload      -> la imagen viene en la petición (multipart o JSON
//                        con base64) y la guardamos en uploads/.
//   POST /upload-url  -> el cliente nos dice nombre y tamaño, y le
//                        devolvemos un formulario firmado para subir
//                        directo a S3 (imágenes de hasta 10 MB).
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { createPresignedPost } from '@aws-sdk/s3-presigned-post';
import { v4 as generarUuid } from 'uuid';
import {
  tiposPermitidos,
  detectarTipoImagen,
  obtenerExtension,
  construirClave,
  claveProcesadaEsperada,
} from './validaciones.mjs';
import { leerArchivoMultipart, ErrorDeCarga } from './lectorMultipart.mjs';

const clienteS3 = new S3Client({});

const configuracion = {
  bucket: process.env.S3_BUCKET,
  prefijoOriginales: process.env.UPLOAD_PREFIX ?? 'uploads/',
  prefijoProcesadas: process.env.PROCESSED_PREFIX ?? 'processed/',
  maximoDirectoBytes: Number(process.env.MAX_DIRECT_BYTES ?? 4 * 1024 * 1024),
  maximoPrefirmadaBytes: Number(process.env.MAX_PRESIGNED_BYTES ?? 10 * 1024 * 1024),
  segundosValidezPrefirmada: Number(process.env.PRESIGNED_EXPIRES_SECONDS ?? 300),
};

function responder(codigoHttp, cuerpo) {
  return {
    statusCode: codigoHttp,
    headers: { 'content-type': 'application/json; charset=utf-8' },
    body: JSON.stringify(cuerpo),
  };
}

function registrar(nivel, mensaje, datos = {}) {
  // Con el formato de logs JSON de Lambda, cada objeto queda como campos
  // filtrables en CloudWatch Logs Insights.
  console[nivel === 'error' ? 'error' : 'log'](JSON.stringify({ nivel, mensaje, ...datos }));
}

function obtenerCuerpo(evento) {
  if (!evento.body) return Buffer.alloc(0);
  return evento.isBase64Encoded ? Buffer.from(evento.body, 'base64') : Buffer.from(evento.body, 'utf8');
}

// Acepta { "fileName": "foto.png", "data": "<base64>" }.
// También tolera el formato data URL: "data:image/png;base64,....".
function leerArchivoJson(cuerpo) {
  let datos;
  try {
    datos = JSON.parse(cuerpo.toString('utf8'));
  } catch {
    throw new ErrorDeCarga('El JSON enviado no es válido.');
  }
  if (!datos?.fileName || !datos?.data) {
    throw new ErrorDeCarga('El JSON debe traer los campos fileName y data (base64).');
  }
  const base64Limpio = String(datos.data).replace(/^data:[^;]+;base64,/, '');
  return {
    nombreArchivo: datos.fileName,
    contenido: Buffer.from(base64Limpio, 'base64'),
  };
}

async function subirImagenDirecta(evento) {
  const tipoContenido = evento.headers?.['content-type'] ?? '';
  const cuerpo = obtenerCuerpo(evento);

  let archivo;
  if (tipoContenido.startsWith('multipart/form-data')) {
    archivo = await leerArchivoMultipart(cuerpo, tipoContenido, configuracion.maximoDirectoBytes);
  } else if (tipoContenido.startsWith('application/json')) {
    archivo = leerArchivoJson(cuerpo);
  } else {
    throw new ErrorDeCarga('Usa multipart/form-data o application/json con la imagen en base64.', 415);
  }

  if (archivo.contenido.length > configuracion.maximoDirectoBytes) {
    throw new ErrorDeCarga(
      `La imagen pesa más de ${configuracion.maximoDirectoBytes / 1024 / 1024} MB. Para archivos grandes usa POST /upload-url.`,
      413,
    );
  }

  const extensionDelNombre = obtenerExtension(archivo.nombreArchivo);
  if (!extensionDelNombre) {
    throw new ErrorDeCarga('Solo se aceptan archivos jpg, jpeg, png, gif o webp.', 415);
  }

  const tipoReal = detectarTipoImagen(archivo.contenido);
  if (!tipoReal) {
    throw new ErrorDeCarga('El contenido del archivo no corresponde a una imagen válida.', 415);
  }

  // Guardamos con la extensión del contenido real, no la que dijo el
  // cliente: un PNG renombrado a .jpg se guarda como .png.
  const clave = construirClave(configuracion.prefijoOriginales, generarUuid(), archivo.nombreArchivo, tipoReal);

  await clienteS3.send(
    new PutObjectCommand({
      Bucket: configuracion.bucket,
      Key: clave,
      Body: archivo.contenido,
      ContentType: tiposPermitidos[tipoReal],
      Metadata: { 'nombre-original': encodeURIComponent(archivo.nombreArchivo).slice(0, 200) },
    }),
  );

  registrar('info', 'imagen_guardada', { clave, bytes: archivo.contenido.length, tipo: tipoReal });

  return responder(201, {
    mensaje: 'Imagen recibida. En unos segundos estará lista la versión circular.',
    bucket: configuracion.bucket,
    clave,
    tamanoBytes: archivo.contenido.length,
    claveProcesada: claveProcesadaEsperada(clave, configuracion.prefijoOriginales, configuracion.prefijoProcesadas),
  });
}

async function generarFormularioPrefirmado(evento) {
  let datos;
  try {
    datos = JSON.parse(obtenerCuerpo(evento).toString('utf8') || '{}');
  } catch {
    throw new ErrorDeCarga('El JSON enviado no es válido.');
  }

  const extension = obtenerExtension(datos.fileName);
  if (!extension) {
    throw new ErrorDeCarga('Indica fileName con extensión jpg, jpeg, png, gif o webp.', 415);
  }

  const tamanoDeclarado = Number(datos.sizeBytes);
  if (!Number.isFinite(tamanoDeclarado) || tamanoDeclarado <= 0) {
    throw new ErrorDeCarga('Indica sizeBytes con el tamaño del archivo en bytes.');
  }
  if (tamanoDeclarado > configuracion.maximoPrefirmadaBytes) {
    throw new ErrorDeCarga(`El máximo permitido es ${configuracion.maximoPrefirmadaBytes / 1024 / 1024} MB.`, 413);
  }

  const tipoContenido = tiposPermitidos[extension];
  const clave = construirClave(configuracion.prefijoOriginales, generarUuid(), datos.fileName, extension);

  // Las condiciones van firmadas: S3 rechaza la subida si el archivo pesa
  // más de lo permitido o si alguien cambia la clave o el tipo. El tamaño
  // lo controla S3, no la palabra del cliente.
  const { url, fields } = await createPresignedPost(clienteS3, {
    Bucket: configuracion.bucket,
    Key: clave,
    Conditions: [
      ['content-length-range', 1, configuracion.maximoPrefirmadaBytes],
      ['eq', '$Content-Type', tipoContenido],
    ],
    Fields: { 'Content-Type': tipoContenido },
    Expires: configuracion.segundosValidezPrefirmada,
  });

  registrar('info', 'formulario_prefirmado_generado', { clave, tamanoDeclarado });

  return responder(200, {
    mensaje: 'Sube el archivo con un POST multipart a "url", enviando todos los "campos" y al final el archivo en el campo "file".',
    url,
    campos: fields,
    clave,
    expiraEnSegundos: configuracion.segundosValidezPrefirmada,
    claveProcesada: claveProcesadaEsperada(clave, configuracion.prefijoOriginales, configuracion.prefijoProcesadas),
  });
}

export async function handler(evento) {
  try {
    switch (evento.routeKey) {
      case 'POST /upload':
        return await subirImagenDirecta(evento);
      case 'POST /upload-url':
        return await generarFormularioPrefirmado(evento);
      default:
        return responder(404, { error: 'Ruta no encontrada.' });
    }
  } catch (error) {
    if (error instanceof ErrorDeCarga) {
      registrar('warn', 'peticion_rechazada', { motivo: error.message, ruta: evento.routeKey });
      return responder(error.codigoHttp, { error: error.message });
    }
    // Error inesperado: lo registramos completo, pero al cliente no le
    // mostramos detalles internos.
    registrar('error', 'error_inesperado', { detalle: error.message, pila: error.stack });
    return responder(500, { error: 'Ocurrió un problema al procesar la imagen. Intenta de nuevo.' });
  }
}