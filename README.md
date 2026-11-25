# Cuentos del pueblo de Pipa

App de Android (tablets y celulares) con cuentos ilustrados de "elegí tu propia aventura" para
chicos de 3 a 12 años con autismo y otras condiciones del neurodesarrollo. Hecha en Godot 4.7.

- Un narrador lee cada página apenas se gira la hoja, con karaoke palabra por palabra.
- Cada página tiene entre 3 y 5 cosas que reaccionan al tocarlas.
- 2 decisiones por cuento, 4 finales y 1 final secreto.
- Colgante de los colores, Rincón de calma con Lumi, panel de adultos detrás de una puerta para padres.
- Funciona sin internet, no pide permisos, no recolecta datos, sin anuncios ni compras.

El elenco (Pipa, Sofi, Bubu, Fido, Tati) viene del juego **Nido**: ver `docs/personajes.md`.

## Estructura

| Carpeta | Qué hay |
|---|---|
| `src/core/` | Lógica sin escenas (probada con GUT): cuento, navegación, guardado, karaoke, puerta para padres… |
| `src/autoload/` | `Store` (guardado atómico en `user://save.json`) y `Audio` (buses, ducking, pausa) |
| `src/ui/` | Pantallas: plaza, portada, reproductor, decisiones, cierre, calma, panel de adultos |
| `src/cast/` | Rig de personajes por piezas (adaptado de Nido) |
| `stories/` | `index.json` (puertas de la plaza) y un directorio por cuento (`story.json`, `art/`, `vo/`, `sfx/`) |
| `schema/` | JSON Schema de `story.json` |
| `tools/` | Validador, TTS, arte provisorio, efectos, capturas para la tienda, release |
| `test/` | Tests de GUT y cuentos de prueba |
| `docs/` | Esquema, personajes, privacidad, seguridad de datos, ficha de Play, release, créditos, árboles de cada cuento |

## Desarrollo

```bash
tools/setup_godot.sh
```

```bash
pip install -r tools/requirements.txt
```

Tests de Godot (GUT, headless):

```bash
.tools/bin/godot --headless --import; .tools/bin/godot --headless -s addons/gut/gut_cmdln.gd
```

Tests de las herramientas y validador de cuentos:

```bash
python3 -m pytest
```

```bash
python3 tools/validate.py stories --trees docs/trees
```

El CI (`.github/workflows/ci.yml`) corre las tres cosas en cada push.

## Agregar o cambiar un cuento

1. Escribir el texto en `tools/content/<id>.py` (o directamente `stories/<id>/story.json`).
   El formato está en `docs/story-schema.md`.
2. Arte provisorio: `python3 tools/art/placeholders.py`.
3. Efectos: `python3 tools/sfx/make_sfx.py`.
4. Voces: `python3 tools/tts/tts.py --story stories/<id> --engine kokoro` (ver `tools/tts/README.md`).
5. Validar: `python3 tools/validate.py stories --trees docs/trees`.
6. Agregar la puerta en `stories/index.json`.

## Publicar

Ver `docs/release.md`: Android SDK, upload key, `tools/release.sh`, Play Console (prueba interna,
prueba cerrada y producción). Capturas y gráficos de la ficha: `tools/store_assets/run.sh`.

## Licencias

Ver `docs/credits.md`.
