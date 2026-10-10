// Lambda de recorte.
//
// La dispara SQS con lotes de hasta 5 mensajes. Cada mensaje es una
// notificación de S3 que avisa que llegó una imagen nueva a uploads/.
//
// Si una imagen falla, solo ESE mensaje se reporta como fallido
// (ReportBatchItemFailures). SQS lo reintenta y, al tercer fallo, lo
// manda a la DLQ, donde salta la alarma.
import { S3Client, GetObjectCommand, PutObjectCommand } from '@aws-sdk/client-s3';
import { recortarEnCirculo, claveDeSalida } from './recorte.mjs';

const clienteS3 = new S3Client({});

const configuracion = {
  bucket: process.env.S3_BUCKET,
  prefijoOriginales: process.env.UPLOAD_PREFIX ?? 'uploads/',
  prefijoProcesadas: process.env.PROCESSED_PREFIX ?? 'processed/',
  tamanoSalida: Number(process.env.OUTPUT_SIZE ?? 40),
};

function registrar(nivel, mensaje, datos = {}) {
  console[nivel === 'error' ? 'error' : 'log'](JSON.stringify({ nivel, mensaje, ...datos }));
}

// S3 manda las claves codificadas como en una URL: los espacios llegan
// como "+" y los caracteres especiales como %XX.
function decodificarClave(claveCodificada) {
  return decodeURIComponent(claveCodificada.replace(/\+/g, ' '));
}

async function procesarImagen(bucket, clave) {
  if (!clave.startsWith(configuracion.prefijoOriginales)) {
    // No debería pasar por el filtro de la notificación, pero si pasa no
    // queremos procesar nuestros propios resultados en bucle.
    registrar('warn', 'clave_ignorada', { clave });
    return;
  }

  const original = await clienteS3.send(new GetObjectCommand({ Bucket: bucket, Key: clave }));
  const contenido = Buffer.from(await original.Body.transformToByteArray());

  const circular = await recortarEnCirculo(contenido, configuracion.tamanoSalida);
  const claveFinal = claveDeSalida(clave, configuracion.prefijoOriginales, configuracion.prefijoProcesadas);

  await clienteS3.send(
    new PutObjectCommand({
      Bucket: bucket,
      Key: claveFinal,
      Body: circular,
      ContentType: 'image/png',
      Metadata: { origen: encodeURIComponent(clave).slice(0, 200) },
    }),
  );

  registrar('info', 'imagen_procesada', {
    origen: clave,
    destino: claveFinal,
    bytesEntrada: contenido.length,
    bytesSalida: circular.length,
  });
}

async function procesarMensaje(mensaje) {
  const cuerpo = JSON.parse(mensaje.body);

  // Cuando se crea la notificación, S3 manda un mensaje de prueba. No hay
  // nada que procesar; se da por bueno para que SQS lo borre.
  if (cuerpo.Event === 's3:TestEvent') {
    registrar('info', 'evento_de_prueba_s3_ignorado');
    return;
  }

  for (const registro of cuerpo.Records ?? []) {
    const bucket = registro.s3?.bucket?.name ?? configuracion.bucket;
    const clave = decodificarClave(registro.s3.object.key);
    await procesarImagen(bucket, clave);
  }
}

export async function handler(evento) {
  const fallidos = [];

  // Los mensajes se procesan uno por uno. Con 5 imágenes de 40x40 el
  // tiempo total es corto y así el uso de memoria se mantiene predecible.
  for (const mensaje of evento.Records ?? []) {
    try {
      await procesarMensaje(mensaje);
    } catch (error) {
      registrar('error', 'fallo_al_procesar', {
        idMensaje: mensaje.messageId,
        intento: mensaje.attributes?.ApproximateReceiveCount,
        detalle: error.message,
      });
      fallidos.push({ itemIdentifier: mensaje.messageId });
    }
  }

  return { batchItemFailures: fallidos };
}