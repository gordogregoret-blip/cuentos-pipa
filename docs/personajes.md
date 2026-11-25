# Personajes — Cuentos del pueblo de Pipa

El elenco es el mismo del juego **Nido** (`gordogregoret-blip/nido`). El arte de los cinco
personajes con dibujo se copió de Nido (`assets/art/pueblo/personajes/` y `shared/`) a
`res://art/cast/`. Se arman por piezas con `src/cast/CharacterRig.gd` (copiado de Nido y adaptado).
Las reglas visuales están en `docs/art/art-direction-brief.md`.

## Elenco fijo

| Nombre | Animal | Id de arte | Cómo es | Arte |
|---|---|---|---|---|
| **Pipa** | Pájara | `pipa` | Protagonista. Alegre. Atiende el café, arregla autos y lleva a todos de paseo. Lleva el Colgante de los colores. | Nido |
| **Sofi** | Coneja | `coneja` | Dulce y amable. | Nido |
| **Bubu** | Oso | `oso` | Grandote y tranquilo. Da abrazos y ayuda a calmarse. | Nido |
| **Fido** | Perro | `perro` | Curioso. Encuentra pistas con el olfato. | Nido |
| **Tati** | Gata | `gato` | Observadora. Hace muchas preguntas. | Nido |
| **Lula** | Tortuga | — | Lenta y sabia. Enseña a esperar. | Placeholder |
| **Coco** | Pato | — | Habla mucho y es gracioso. | Placeholder |
| **Lumi** | Luciérnaga | — | Vive en el colgante. Da pistas y guía la calma. | Placeholder |

Los placeholders son formas simples con el nombre escrito, generados por
`tools/art/placeholders.py` con la paleta de Nido. Se reemplazan cuando haya arte final.

## Gestos del rig (estados de `CharacterRig`)

`idle`, `hablar`, `contento`, `triste`, `saludar`, `comer`, `esperar`, `caminar`, `sorpresa`,
`pensar`, `bailar`. Cada personaje tiene además un gesto propio que hace de vez en cuando:
Pipa aletea, Sofi mueve las orejas, Bubu bosteza, Fido da un saltito, Tati inclina la cabeza.
En modo calma (`Motion.reduced`) no respiran ni hacen gestos propios.

## El Colgante de los colores

Lo lleva Pipa. Su color muestra cómo se siente ella, y la voz siempre lo nombra en dos frases
literales: "El colgante está azul. Pipa está triste."

| Color | Emoción |
|---|---|
| Amarillo | contenta |
| Azul | triste |
| Rojo | enojada |
| Violeta | sorprendida |
| Verde | tranquila |
| Naranja | con miedo o nerviosa |

El cambio de color se anima por código (`modulate`, fundido suave de 600 ms, sin destellos).

## Marco de la colección

En la plaza del pueblo está el **Árbol de las Puertas**. Cada puerta lleva a un mundo (un cuento).
Al terminar un cuento, Pipa planta una **semilla de luz** en el árbol. Con 7 semillas, el árbol
florece (cuento 8, "La gran fiesta del Árbol").

## Reglas de escritura para todos los personajes

- Lenguaje literal: sin ironías, sin metáforas, sin dobles sentidos.
- Siempre se nombra la emoción de Pipa y el color del colgante cuando cambia.
- Nadie se burla de nadie. Nadie pierde. Pedir ayuda está bien.
