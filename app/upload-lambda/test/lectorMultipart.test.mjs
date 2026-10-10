import { test } from 'node:test';
import assert from 'node:assert/strict';
import { leerArchivoMultipart, ErrorDeCarga } from '../src/lectorMultipart.mjs';

function armarMultipart(nombreArchivo, contenido) {
  const limite = '----limitePrueba';
  const cuerpo = Buffer.concat([
    Buffer.from(
      `--${limite}\r\nContent-Disposition: form-data; name="file"; filename="${nombreArchivo}"\r\n` +
        'Content-Type: image/png\r\n\r\n',
    ),
    contenido,
    Buffer.from(`\r\n--${limite}--\r\n`),
  ]);
  return { cuerpo, tipo: `multipart/form-data; boundary=${limite}` };
}

test('extrae el archivo y su nombre', async () => {
  const { cuerpo, tipo } = armarMultipart('gato.png', Buffer.from('contenido-de-prueba'));
  const archivo = await leerArchivoMultipart(cuerpo, tipo, 1024);
  assert.equal(archivo.nombreArchivo, 'gato.png');
  assert.equal(archivo.contenido.toString(), 'contenido-de-prueba');
});

test('rechaza con 413 si el archivo supera el límite', async () => {
  const { cuerpo, tipo } = armarMultipart('grande.png', Buffer.alloc(2048));
  await assert.rejects(
    () => leerArchivoMultipart(cuerpo, tipo, 1024),
    (error) => error instanceof ErrorDeCarga && error.codigoHttp === 413,
  );
});