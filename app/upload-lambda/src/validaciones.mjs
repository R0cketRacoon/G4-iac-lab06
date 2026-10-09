// Reglas para decidir si un archivo es una imagen aceptable.
// No confiamos en la extensión ni en el Content-Type que manda el
// cliente: miramos los primeros bytes del archivo ("magic bytes"), que
// son difíciles de falsificar sin romper la imagen.

export const tiposPermitidos = {
  jpg: 'image/jpeg',
  png: 'image/png',
  gif: 'image/gif',
  webp: 'image/webp',
};

// Extensiones que aceptamos en el nombre y la extensión con la que
// guardamos el archivo. jpeg se normaliza a jpg.
const extensionesAceptadas = {
  jpg: 'jpg',
  jpeg: 'jpg',
  png: 'png',
  gif: 'gif',
  webp: 'webp',
};

/**
 * Devuelve 'jpg', 'png', 'gif' o 'webp' según el contenido real del
 * archivo, o null si no es ninguno de esos formatos.
 */
export function detectarTipoImagen(contenido) {
  if (!contenido || contenido.length < 12) return null;

  const empiezaCon = (...bytes) => bytes.every((byte, i) => contenido[i] === byte);

  if (empiezaCon(0xff, 0xd8, 0xff)) return 'jpg';
  if (empiezaCon(0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a)) return 'png';

  const cabecera = contenido.subarray(0, 6).toString('ascii');
  if (cabecera === 'GIF87a' || cabecera === 'GIF89a') return 'gif';

  // WebP: "RIFF" + 4 bytes de tamaño + "WEBP"
  const riff = contenido.subarray(0, 4).toString('ascii');
  const webp = contenido.subarray(8, 12).toString('ascii');
  if (riff === 'RIFF' && webp === 'WEBP') return 'webp';

  return null;
}

/**
 * Saca la extensión del nombre que mandó el cliente y la normaliza.
 * Devuelve null si no es una de las permitidas.
 */
export function obtenerExtension(nombreArchivo = '') {
  const partes = String(nombreArchivo).toLowerCase().split('.');
  if (partes.length < 2) return null;
  return extensionesAceptadas[partes.pop()] ?? null;
}

/**
 * Limpia el nombre para usarlo dentro de la clave de S3: sin rutas, sin
 * espacios raros y con un largo razonable. Así nadie puede colar algo como
 * "../../processed/x.png" para escribir donde no debe.
 */
export function sanearNombre(nombreArchivo = '') {
  const sinRuta = String(nombreArchivo).split(/[\\/]/).pop();
  const sinExtension = sinRuta.replace(/\.[^.]*$/, '');
  const limpio = sinExtension
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '') // quita tildes
    .replace(/[^a-zA-Z0-9_-]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 60);
  return limpio || 'imagen';
}

/**
 * Arma la clave final en S3: uploads/<uuid>-<nombre>.<ext>
 * El uuid evita que dos personas que suben "foto.jpg" se pisen.
 */
export function construirClave(prefijo, idUnico, nombreArchivo, extension) {
  return `${prefijo}${idUnico}-${sanearNombre(nombreArchivo)}.${extension}`;
}

/**
 * Calcula dónde quedará la versión recortada, para decírselo al cliente.
 */
export function claveProcesadaEsperada(claveOriginal, prefijoOriginales, prefijoProcesadas) {
  const sinPrefijo = claveOriginal.slice(prefijoOriginales.length);
  const base = sinPrefijo.replace(/\.[^.]+$/, '');
  return `${prefijoProcesadas}${base}_circular.png`;
}