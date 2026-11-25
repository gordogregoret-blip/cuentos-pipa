# Créditos y licencias

Todo lo que trae la app es de uso libre o propio. No se incluye ningún SDK de terceros.

## Código

| Componente | Autor | Licencia |
|---|---|---|
| Motor Godot 4.7 | Juan Linietsky, Ariel Manzur y colaboradores | MIT |
| GUT (tests, solo en desarrollo, no va en la app) | Butch Wesley y colaboradores | MIT |
| Rig de personajes (`src/cast/`) | Proyecto Nido (mismo autor) | Propio |

## Arte

| Recurso | Autor | Licencia |
|---|---|---|
| Elenco: Pipa, Sofi, Bubu, Fido, Tati (`art/cast/`) | Proyecto Nido (mismo autor) | Propio |
| Íconos de la interfaz, plaza, árbol, puertas (`art/ui/`) | Hechos para este proyecto | Propio |
| Arte provisorio de los cuentos (`stories/*/art/`) | Generado por `tools/art/placeholders.py` | Propio |

## Tipografías

| Fuente | Autor | Licencia |
|---|---|---|
| Nunito | Vernon Adams, Cyreal, Jacques Le Bailly | SIL Open Font License 1.1 (`fonts/OFL-Nunito.txt`) |
| Atkinson Hyperlegible | Braille Institute of America | SIL Open Font License 1.1 (`fonts/OFL-Atkinson.txt`) |

## Sonido

| Recurso | Autor | Licencia |
|---|---|---|
| Efectos (`stories/*/sfx/*.ogg`): brillo, campanita, campanitas, puerta, guau, miau, pío, olfato, paso, hojas, burbuja, agua, aleteo, viento, abrazo, rugido suave, pop | Sintetizados por código en `tools/sfx/make_sfx.py` | CC0 1.0 (dominio público) |
| Música de la plaza (`audio/music/plaza.ogg`) | Sintetizada por código en `tools/sfx/make_sfx.py` | CC0 1.0 (dominio público) |

Si se reemplazan por efectos de Kenney (CC0) o de Freesound (solo CC0), anotar acá el autor,
la URL de origen y la licencia de cada archivo.

## Voces

| Recurso | Motor | Licencia del motor y de la voz |
|---|---|---|
| Relatos, palabras, opciones, títulos y frases de la interfaz (`stories/*/vo/`, `audio/ui/`) | Kokoro-82M (hexgrad), voz `ef_dora`, fonemas es-419 | Apache-2.0 |
| Alternativa configurable | Piper (rhasspy), voces `es_MX-claude-high` / `es_MX-ald-medium` | MIT (motor) / ver la ficha de cada voz en Hugging Face |

Los motores de voz se usan solo en la computadora del autor para generar los archivos;
no van dentro de la app.
