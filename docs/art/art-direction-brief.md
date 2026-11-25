# Brief de dirección de arte — El Café de Pipa

Estado: **aprobado por Luis** (2026-11-20). En uso en el MVP: pueblo + café.
Pieza de referencia: captura `docs/art/cafe-spike-1080x1920.png`; arte en `assets/art/pueblo/`.
Cada lugar nuevo arranca con una pieza de referencia aprobada antes de producir su familia.

## Marco del juego

- Fantasía del jugador: ayudar a Pipa a atender su café; los clientes piden, vos armás el pedido.
- Verbos: tocar, arrastrar (más adelante), mirar la cara del cliente.
- Motor: Godot 4.7, renderer `gl_compatibility` (Android).
- Vista: frontal, plana, una sola escena fija (el chico nunca "navega").
- Viewport nativo: 1080×1920 retrato, `stretch_mode = canvas_items`.
- Tamaños en pantalla: Pipa ~600 px de alto; cliente ~780 px con orejas; comida 200–260 px de ancho.

## Sistema visual

- **Formas**: todo redondeado; círculos, elipses y huevos. Ninguna esquina viva en personajes ni
  comida (radio mínimo 14 px en lo rectangular). Siluetas que se reconocen solo por el contorno.
- **Proporciones de personajes** ("cabezones", tipo preescolar):
  - Cabeza ≥ 50% de lo que se ve arriba del mostrador. Pipa: cabeza Ø340, cuerpo huevo 380×400.
  - Clientes: cabeza ancha (350×300), cuerpo más angosto que la cabeza (300×350).
  - Ojos grandes y separados (≈ 1/3 del ancho de la cabeza entre centros). **Un solo ojo
    compartido por todos los personajes** (`shared/ojo_*.svg`): elipse 38×50 tinta con brillo
    blanco arriba a la derecha. Es lo que hace que todos "sean de la misma familia".
  - Mejillas rosadas siempre. Boca/pico como pieza aparte (la boca es la que más cambia).
- **Proporciones de comidas**: 200–260 px de ancho, vista canónica (banana de perfil, medialuna
  de frente, vaso de costado). Un brillo claro por pieza. **Las comidas no tienen cara**: solo los
  personajes tienen ojos, para que nunca haya duda de quién es "alguien" y qué es "algo".
- **Línea**: tinta `#4A2E22` (marrón muy oscuro, nunca negro). Contorno exterior **8 px**, detalles
  interiores **6 px**, puntas y uniones redondas. Escala nativa 1080×1920.
- **Figura y fondo** (la regla más importante para él):
  - El **fondo no tiene contorno**: colores claros y apagados, poco contraste interno.
  - **Personajes y cosas que se tocan sí tienen contorno** y son los colores más saturados.
  - Así, lo que tiene línea es lo importante, y el ojo va directo ahí.
- **Luz**: plana, sin sombras proyectadas ni degradés. Volumen solo con una mancha más clara
  (brillo) o una franja más oscura del mismo tono.
- **Densidad**: fondo con pocos elementos grandes (ventana, banderín, zócalo). Nada que parezca
  tocable sin serlo.
- **Movimiento** (para cuando se anime): suave y elástico, 150–300 ms, rebote chico. Respiración en
  reposo. Nada brusco ni que parpadee rápido.
- **Exclusiones**: emoji, OpenMoji, PNG generados por IA, mezclar fuentes de arte, texto dentro
  del arte, degradés, filtros/sombras SVG, texturas, negro puro, rojo de "error".

### Paleta (roles y valores exactos)

| Rol | Color | Uso |
|---|---|---|
| Tinta | `#4A2E22` | contornos, ojos, detalles |
| Pared | `#D9EEE4` / puntos `#CDE7DB` | fondo frío y calmo, contrasta con personajes cálidos |
| Zócalo | `#F2D3AE` / moldura `#E4B887` | |
| Banderín | `#F2836B` coral / `#FFF6E8` crema | identidad de "café" |
| Ventana | marco `#FFFFFF`, cielo `#BFE4F2`, loma `#A8D59A`, sol `#FFD86B` | |
| Mostrador | tapa `#E9AE7B` / filo `#F4C595` / sombra `#B9784C` / frente `#D08E5C` | |
| Vitrina | marco `#F6E3C8`, vidrio `#EAF6F8`, estante `#E4B887` | |
| Pipa | crema `#FFF1DA`, panza `#FFF8EC`, capucha `#5A4136`, alas `#C8693B`, pico `#F59B2F` | |
| Delantal | `#5BB5A8`, bolsillo `#4A9C90` | color "de la casa" |
| Clienta coneja | pelo `#BDB2E3`, hocico `#FFF4E6`, oreja/nariz `#F7B3C2`/`#F28FA3`, pañuelo `#F2836B` | |
| Mejillas | `#F9B9A6` | todos los personajes |
| Interior boca | `#7A3B2E` | |
| Banana | `#FFD23F`, brillo `#FFE680`, puntas `#8A5A35` | |
| Medialuna | `#E9A24A`, brillo `#F7C77A` | |
| Jugo | `#FF9F1C`, superficie `#FFC15A`, vaso `#E3F3F6`, rodaja `#FFB347`, sorbete `#F2836B` | |
| Globo / plato | `#FFFFFF`, interior plato `#F1E6D6` | |

## Contrato técnico

- Formato: SVG escrito a mano, en píxeles nativos de 1080×1920 (import `svg/scale = 1.0`).
- Solo `path`, `circle`, `ellipse`, `rect`, `transform` y `stroke`. Nada de `filter`, `mask`,
  `text`, degradés ni imágenes embebidas (ThorVG los soporta a medias y rompen la consistencia).
- **Piezas de recorte con pivote en el origen**: cada parte se dibuja en coordenadas locales con
  su punto de giro en (0,0); el `viewBox` es el recorte. En Godot: `Sprite2D` con
  `centered = false` y `offset = (minX, minY)` del viewBox, colgado de un `Node2D` ubicado en el
  pivote. Las partes simétricas (ala, oreja, ojo) son **un solo archivo** (espejo con `scale.x = -1`).
- Comidas y props: pivote abajo al centro (apoyan en el plato).
- Fondo y mostrador: en coordenadas de pantalla (el mostrador es una capa delantera que tapa la
  parte baja de los personajes).
- Filtro lineal, sin mipmaps. Alfa real (SVG); se valida con `scripts/tools/art_qa.gd`.
- Carpetas: `assets/art/pueblo/{personajes,shared,cafe,calle,ui}`; nombres en
  castellano, `snake_case`.
- Registro: `assets/art/pueblo/asset-manifest.json` (fuente, licencia, tamaño y origen del viewBox de cada pieza).

## Objetivo visual

- Referencia aprobada: la captura del spike del café a 1080×1920
  (`docs/art/cafe-spike-1080x1920.png`).
- QA técnico: `scripts/tools/art_qa.gd` (tamaño, alfa real, contorno no recortado + hoja de
  contactos). Reemplaza a `asset_report.py`/`build_preview_sheet.py` porque no hay Python acá.
- Aprobación: Luis, 2026-11-20 ("ya tenemos el bar").
