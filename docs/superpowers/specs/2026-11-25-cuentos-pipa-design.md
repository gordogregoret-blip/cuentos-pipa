# Cuentos del pueblo de Pipa — diseño

Estado: aprobado por el dueño del proyecto (2026-11-25).
Pedido completo y fuente de verdad de requisitos: `2026-11-25-pedido-original.md` (en esta carpeta).
Este documento registra solo lo que se decidió encima del pedido.

## Intención

App Android paga (Google Play, Política de Familias) de cuentos ilustrados de "elegí tu propia
aventura" para chicos de 3 a 12 años con autismo y otras condiciones del neurodesarrollo.
Prioridades: previsibilidad (controles fijos, relato automático, nada de perder ni de tiempo
límite), calma sensorial, cero datos personales.

## Objetivos / no objetivos / anti-objetivos

- Objetivos: StoryPlayer genérico guiado por datos; "El huevo que brillaba" completo con 4 finales
  y final secreto; plaza con 2 cuentos jugables y 6 bloqueados; panel del adulto; .aab listo para
  la pista de prueba interna; material de Play.
- No objetivos: voces reales (se generan en la PC del dueño), Play Asset Delivery, arte final de
  personajes nuevos, los cuentos 3 a 8.
- Anti-objetivos (falla aunque "funcione"): pedir cualquier permiso; enlaces fuera del panel del
  adulto; flashes, sonidos fuertes o apuro; texto con ironías o metáforas; tocar el repo de Nido.

## Enfoque elegido

Una sola forma razonable, porque el pedido fija el stack (Godot 4.7, GDScript tipado, GUT,
gl_compatibility):

- **Cuentos como datos**: `res://stories/<id>/story.json` validado con JSON Schema. Un StoryPlayer
  genérico los reproduce.
- **Lógica sin escenas**: grafo de páginas, marcas, progreso, guardado y migración, nivel de texto
  por edad y puerta para padres viven en clases `RefCounted` probadas con GUT (TDD). Las escenas
  solo muestran y conectan señales.
- **Herramientas en Python** (`tools/`): validador + Mermaid, TTS, voces provisorias, capturas para
  la tienda. Tests con pytest. CI en GitHub Actions corre pytest, el validador y GUT headless.

Alternativas descartadas: escenas `.tscn` hechas a mano por página (no escala a 8 cuentos ni se
puede validar); motor web/Flutter (contradice el pedido y el elenco de Nido).

## Decisiones tomadas en la conversación

1. **Elenco desde Nido** (`gordogregoret-blip/nido`, solo lectura): se copian
   `assets/art/pueblo/personajes/*.svg` **y** `assets/art/pueblo/shared/*.svg` (ojos, bocas, cejas
   compartidos) a `res://art/cast/` y `res://art/cast/shared/`, más una copia adaptada de
   `CharacterRig.gd` / `CharacterDefs.gd` para armar los personajes por piezas. Correspondencia:
   Pipa = pipa, Sofi = coneja, Bubu = oso, Fido = perro, Tati = gato.
2. **`docs/personajes.md`** no existe en Nido: se escribe a partir de la tabla del pedido y lo que
   dicen el GDD/specs de Nido. `docs/art/art-direction-brief.md` se copia tal cual (paleta y reglas).
3. **Final secreto**: cada recorrido es P1, P2, X3, X4, P5, P6, P7 (7 páginas). Huellas: `huella_1`
   en P1, `huella_2` en A3 o B3, `huella_3` en cualquier P5. Con las 3, el "Siguiente" de cualquier
   P5 va a la P6 secreta (Pipa le enseña a volar a la ptera bebé) en lugar de su P6 normal.
4. **Voces provisorias**: .ogg de silencio con la duración estimada por sílabas + JSON de tiempos
   por palabra, generados por `tools/tts --engine placeholder`. Las voces reales (Kokoro/Piper) las
   corre el dueño en su PC con el mismo script.
5. **Efectos**: sonidos suaves sintetizados por código (obra propia, CC0) y registrados en
   `docs/credits.md`. Reemplazables por Kenney/Freesound CC0.
6. **Tipografía de lectura fácil**: Atkinson Hyperlegible (OFL) si se puede descargar; si no,
   la fuente por defecto con más espaciado, anotado.
7. **Export Android**: se intenta compilar el .aab firmado en el contenedor con una clave de prueba
   (Android SDK + plantillas de Godot). Clave real de subida, prueba en tablet y Play Console los
   hace el dueño siguiendo `docs/release.md`.
8. **Repo**: se arma en local (`/home/user/cuentos-pipa`) y se sube a `gordogregoret-blip/cuentos-pipa`
   cuando el dueño lo cree en GitHub (la sesión no puede crear repos).

## Qué queda a criterio del constructor

Estructura interna de escenas, nombres de clases, formato exacto del JSON de tiempos, curvas de
animación (dentro de 150–400 ms, suaves), diseño visual de placeholders respetando la paleta de
Nido, textos de los 3 niveles del cuento (literales, nombrando emoción y color del colgante).

## Límites de verificación

No se puede verificar en este entorno: tablet real, subida a Play Console, voces reales. Todo lo
demás se verifica con tests, validador, ejecuciones headless y capturas.
