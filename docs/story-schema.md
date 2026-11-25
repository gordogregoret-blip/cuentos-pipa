# Esquema de los cuentos (`story.json`)

Cada cuento vive en `stories/<id>/`:

```
stories/<id>/
  story.json      el cuento (este documento)
  art/            fondos, objetos y personajes propios (SVG o WebP)
  vo/             voces .ogg (mono 64 kbps) + tiempos .json para el karaoke
  sfx/            efectos .ogg (96 kbps)
```

El esquema formal es `schema/story.schema.json` (JSON Schema 2020-12). El validador
`tools/validate.py` lo aplica y además revisa el grafo y los archivos.

## Nivel superior

| Campo | Tipo | Descripción |
|---|---|---|
| `schema` | `1` | Versión del formato. |
| `id` | texto `[a-z0-9_]` | Igual al nombre de la carpeta. |
| `title` | texto | Título que dice la voz en la plaza. |
| `cast` | lista | Personajes que van (`pipa`, `sofi`, `bubu`, `fido`, `tati` o propios). |
| `message` | texto | Mensaje final dicho en una frase. |
| `start` | id de página | Primera página. |
| `preview` | bool | `true` en cuentos incompletos de prueba: se permite `next: null`. |
| `door_color` | `#RRGGBB` | Color de la puerta en el árbol (opcional). |
| `secret` | objeto | `requires`: marcas necesarias; `page`: página del final secreto. |
| `pages` | objeto | Páginas por id. |

## Página

| Campo | Tipo | Descripción |
|---|---|---|
| `background` | ruta | Fondo, relativo a la carpeta del cuento. |
| `text` | `{simple, cuento, aventura}` | Texto de cada nivel. Lenguaje literal. |
| `pendant` | lista `{color, at}` | Cambios del colgante. `at` = fracción del relato (0 a 1). Colores: `amarillo`, `azul`, `rojo`, `violeta`, `verde`, `naranja`. |
| `characters` | lista `{id, x, y, scale?, state?, flip?}` | `id` del elenco o ruta a un SVG propio. `x`, `y` en fracción de pantalla (pies). |
| `tappables` | lista (3 a 5) | Ver abajo. |
| `next` | id o `null` | Página siguiente. |
| `decision` | `{options: [2 × {text, image, to}]}` | Dos tarjetas grandes. |
| `secret_next` | id | Solo en las P5: adónde se va si están todas las marcas de `secret.requires`. |
| `ending` | `{id, title, secret?}` | Esta página es un final (estrella en la plaza). |
| `closing` | `true` | Página de cierre común (P7): semilla, mensaje, emoción y botones. |

Cada página tiene **exactamente una** salida: `next`, `decision` o `closing`.

## Tocable

| Campo | Descripción |
|---|---|
| `id` | Único en la página `[a-z0-9_]`. |
| `art` | Ruta a SVG, o `cast:<id>` para usar un personaje del elenco. |
| `x`, `y` | Centro, en fracción de pantalla. |
| `size` | Lado en px de la base 1920×1080 (mínimo 96 px = zona táctil ≥ 64 dp). |
| `anim` | `bounce`, `wiggle`, `hop`, `spin`, `grow`, `float` (todas suaves, 150–400 ms). |
| `sfx` | Efecto .ogg. |
| `word` | Lo que dice la voz al tocarlo ("¡Guau! Fido"). |
| `flag` | Marca que activa (`huella_1`…), opcional. |

## Archivos de voz (por convención, no se listan)

| Archivo | Qué es |
|---|---|
| `vo/title.ogg` | Título del cuento. |
| `vo/message.ogg` | Mensaje final. |
| `vo/<página>_<nivel>.ogg` | Relato de la página en ese nivel. |
| `vo/<página>_<nivel>.json` | Tiempos por palabra: `[{"w": "Pipa", "t0": 0.0, "t1": 0.42}, …]` (segundos). |
| `vo/<página>_tap_<id>.ogg` | La palabra del tocable. |
| `vo/<página>_opt<n>.ogg` | Texto de la opción *n* (1 o 2) de una decisión. |

Las palabras de los tiempos coinciden una a una con las palabras del texto separadas por espacios.
`tools/tts/tts.py` genera todos estos archivos a partir de `story.json`.

## Índice de la plaza (`stories/index.json`)

```json
{"stories": [
  {"id": "dino", "title": "El huevo que brillaba", "door_color": "#7FC28E", "locked": false},
  {"id": "selva", "title": "La selva que perdió su canción", "door_color": "#5BB5A8", "locked": true}
]}
```

Las puertas con `"locked": true` aparecen cerradas con el cartel "Próximamente" y no necesitan carpeta.

## Validar

```bash
python3 tools/validate.py stories --trees docs/trees
```

El CI corre lo mismo con `--check-trees` para avisar si los árboles quedaron desactualizados.
