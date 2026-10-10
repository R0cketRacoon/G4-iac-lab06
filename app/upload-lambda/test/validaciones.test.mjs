import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  detectarTipoImagen,
  obtenerExtension,
  sanearNombre,
  construirClave,
  claveProcesadaEsperada,
} from '../src/validaciones.mjs';

const relleno = Buffer.alloc(16);

test('reconoce los cuatro formatos por sus primeros bytes', () => {
  assert.equal(detectarTipoImagen(Buffer.concat([Buffer.from([0xff, 0xd8, 0xff, 0xe0]), relleno])), 'jpg');
  assert.equal(
    detectarTipoImagen(Buffer.concat([Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]), relleno])),
    'png',
  );
  assert.equal(detectarTipoImagen(Buffer.concat([Buffer.from('GIF89a'), relleno])), 'gif');
  assert.equal(detectarTipoImagen(Buffer.concat([Buffer.from('RIFF1234WEBP'), relleno])), 'webp');
});

test('un texto renombrado como .png no pasa', () => {
  assert.equal(detectarTipoImagen(Buffer.from('hola, soy un archivo de texto')), null);
});

test('solo acepta las extensiones del diagrama', () => {
  assert.equal(obtenerExtension('Foto.JPEG'), 'jpg');
  assert.equal(obtenerExtension('logo.webp'), 'webp');
  assert.equal(obtenerExtension('documento.pdf'), null);
  assert.equal(obtenerExtension('sin-extension'), null);
});

test('el nombre no puede escaparse de la carpeta uploads/', () => {
  assert.equal(sanearNombre('../../processed/truco.png'), 'truco');
  assert.equal(sanearNombre('C:\\Users\\ana\\Mi Foto Ñandú.jpg'), 'Mi-Foto-Nandu');
  assert.equal(sanearNombre('...'), 'imagen');
});

test('arma la clave original y la procesada', () => {
  const clave = construirClave('uploads/', 'id-1', 'mi foto.png', 'png');
  assert.equal(clave, 'uploads/id-1-mi-foto.png');
  assert.equal(claveProcesadaEsperada(clave, 'uploads/', 'processed/'), 'processed/id-1-mi-foto_circular.png');
});