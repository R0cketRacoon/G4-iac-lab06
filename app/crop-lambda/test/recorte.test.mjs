import { test } from 'node:test';
import assert from 'node:assert/strict';
import sharp from 'sharp';
import { recortarEnCirculo, claveDeSalida } from '../src/recorte.mjs';

// Imagen roja de 200x100: no es cuadrada a propósito, para comprobar que
// el recorte "cover" no la deforma.
async function crearImagenDePrueba(formato) {
  return sharp({ create: { width: 200, height: 100, channels: 3, background: '#d32f2f' } })
    .toFormat(formato)
    .toBuffer();
}

for (const formato of ['jpeg', 'png', 'gif', 'webp']) {
  test(`un ${formato} sale como PNG circular de 40x40`, async () => {
    const salida = await recortarEnCirculo(await crearImagenDePrueba(formato), 40);
    const datos = await sharp(salida).metadata();

    assert.equal(datos.format, 'png');
    assert.equal(datos.width, 40);
    assert.equal(datos.height, 40);
    assert.equal(datos.hasAlpha, true);
  });
}

test('las esquinas quedan transparentes y el centro opaco', async () => {
  const salida = await recortarEnCirculo(await crearImagenDePrueba('png'), 40);
  const { data, info } = await sharp(salida).raw().toBuffer({ resolveWithObject: true });
  const alfaEn = (x, y) => data[(y * info.width + x) * info.channels + 3];

  assert.equal(alfaEn(0, 0), 0, 'esquina superior izquierda');
  assert.equal(alfaEn(39, 39), 0, 'esquina inferior derecha');
  assert.equal(alfaEn(20, 20), 255, 'centro');
});

test('un archivo que no es imagen lanza error', async () => {
  await assert.rejects(() => recortarEnCirculo(Buffer.from('esto no es una imagen'), 40));
});

test('la clave de salida conserva el nombre y agrega _circular.png', () => {
  assert.equal(
    claveDeSalida('uploads/abc-foto.jpg', 'uploads/', 'processed/'),
    'processed/abc-foto_circular.png',
  );
});