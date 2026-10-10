// Toda la lógica de imagen vive aquí, separada del manejo de S3 y SQS,
// para poder probarla en la computadora sin tocar AWS.
import sharp from 'sharp';

/**
 * Convierte cualquier imagen en un PNG cuadrado con un círculo visible y
 * las esquinas transparentes.
 *
 * Pasos:
 *  1. rotate() sin argumentos respeta la orientación EXIF; sin esto, las
 *     fotos de celular a veces salen de costado.
 *  2. resize "cover" llena el cuadrado recortando lo que sobra, sin
 *     deformar la imagen.
 *  3. ensureAlpha() agrega el canal de transparencia (los JPG no lo traen).
 *  4. La máscara SVG es un círculo blanco; con el modo "dest-in" solo
 *     sobrevive lo que queda dentro del círculo.
 */
export async function recortarEnCirculo(contenidoOriginal, tamanoPixeles = 40) {
  const radio = tamanoPixeles / 2;
  const mascaraCircular = Buffer.from(
    `<svg width="${tamanoPixeles}" height="${tamanoPixeles}" xmlns="http://www.w3.org/2000/svg">
       <circle cx="${radio}" cy="${radio}" r="${radio}" fill="#ffffff"/>
     </svg>`,
  );

  // Primero dejamos la imagen ya cuadrada en un buffer propio. Aplicar la
  // máscara en una segunda pasada evita sorpresas con el orden interno de
  // operaciones de sharp.
  const cuadrada = await sharp(contenidoOriginal, { animated: false, failOn: 'error' })
    .rotate()
    .resize(tamanoPixeles, tamanoPixeles, { fit: 'cover', position: 'centre' })
    .ensureAlpha()
    .png()
    .toBuffer();

  return sharp(cuadrada)
    .composite([{ input: mascaraCircular, blend: 'dest-in' }])
    .png({ compressionLevel: 9 })
    .toBuffer();
}

/**
 * uploads/abc-foto.jpg  ->  processed/abc-foto_circular.png
 */
export function claveDeSalida(claveOriginal, prefijoOriginales, prefijoProcesadas) {
  const sinPrefijo = claveOriginal.startsWith(prefijoOriginales)
    ? claveOriginal.slice(prefijoOriginales.length)
    : claveOriginal;
  const base = sinPrefijo.replace(/\.[^.]+$/, '');
  return `${prefijoProcesadas}${base}_circular.png`;
}