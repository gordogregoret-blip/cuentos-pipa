# Proyecto: Cuentos del pueblo de Pipa — app de cuentos interactivos para Google Play

## Qué vamos a construir
Una app para Android (tablets y celulares) que se publica en Google Play como app paga.
Tiene cuentos ilustrados de "elegí tu propia aventura" para chicos de 3 a 12 años con autismo
y otras condiciones del neurodesarrollo. Cada cuento tiene 7 páginas por recorrido,
2 decisiones, 4 finales y 1 final secreto. Un narrador lee cada página apenas se gira, y
cada página tiene entre 3 y 5 objetos que reaccionan al tocarlos con animación y sonido.
Cada cuento termina con un mensaje dicho en una frase.

Usá superpowers:brainstorming solo para confirmar dudas reales. Después escribí el plan
(superpowers:writing-plans) e implementalo por etapas con TDD.

## Repo y relación con Nido
- Es un repo NUEVO, separado de Nido: `cuentos-pipa`.
- El elenco es el mismo del juego Nido. Pedime la ruta local de mi clon de Nido y copiá:
  - `assets/art/pueblo/personajes/*.svg` → `res://art/cast/` (Pipa, Sofi, Bubu, Fido, Tati)
  - `docs/personajes.md` → `docs/personajes.md`
  - `docs/art/art-direction-brief.md` → `docs/art/art-direction-brief.md`
  - Paleta y reglas de estilo: respetá la guía de arte de Nido. Nada de emoji, nada de OpenMoji.
- No modifiques nada adentro del repo de Nido.

## Elenco (fijo)
| Nombre | Animal | Rol |
|---|---|---|
| Pipa | Pájara | Protagonista. Alegre, atiende el café, arregla autos, lleva a todos de paseo. Lleva el Colgante de los colores. |
| Sofi | Coneja | Dulce y amable |
| Bubu | Oso | Grandote tranquilo, da abrazos y calma |
| Fido | Perro | Curioso, encuentra pistas con el olfato |
| Tati | Gata | Observadora y preguntona |
| Lula | Tortuga | Lenta y sabia, enseña a esperar (SIN arte: placeholder) |
| Coco | Pato | Charlatán y gracioso (SIN arte: placeholder) |
| Lumi | Luciérnaga | Vive en el colgante, da pistas y guía la calma (SIN arte: placeholder) |

Colgante de los colores: amarillo = contenta, azul = triste, rojo = enojada,
violeta = sorprendida, verde = tranquila, naranja = con miedo o nerviosa.
El cambio de color se anima por código (modulate) y la voz lo nombra:
"El colgante está azul. Pipa está triste."

Marco de toda la colección: en la plaza del pueblo está el Árbol de las Puertas. Cada puerta
lleva a un mundo (un cuento). Al terminar un cuento, Pipa planta una semilla de luz en el árbol.
Con 7 semillas, el árbol florece (cuento 8).

## Stack
- Godot 4.7 (la misma versión que Nido), GDScript con tipado estático.
- Renderer gl_compatibility (máxima compatibilidad en Android).
- Orientación horizontal (sensor_landscape). Base 1920x1080 con stretch canvas_items y
  aspect expand: tiene que verse bien en tablets 4:3 y 16:10 y en celulares 20:9.
  Los controles respetan las zonas seguras (notch y barras).
- Sin dependencias pagas ni SDKs de terceros: ni analytics, ni ads, ni crash reporting externo.
- Funciona 100% sin conexión. El manifest NO pide el permiso INTERNET ni ningún otro.
- Tests con GUT (headless). El validador de cuentos corre en CI (GitHub Actions).

## Requisitos de Google Play (obligatorios)
1. **Formato y SDK**: exportar como Android App Bundle (.aab) con Gradle build.
   targetSdk = 36 (Android 16), que es lo que Play exige desde el 31/08/2026 para apps nuevas.
   minSdk = 24. Arquitecturas arm64-v8a y armeabi-v7a.
2. **Firma**: Play App Signing. Generá la upload key con keytool, pero el keystore y las
   contraseñas van FUERA del repo (variables de entorno o un archivo ignorado por git).
   Documentá el proceso en docs/release.md. Nunca commitees el .keystore ni el .env.
3. **Política de Familias**: el público objetivo incluye chicos (5 años o menos, 6-8 y 9-12),
   así que:
   - Cero SDKs no aprobados para chicos, cero ubicación, cero identificadores del dispositivo,
     cero recolección de datos personales.
   - Sin publicidad, sin compras dentro de la app, sin enlaces a redes sociales.
   - Todo enlace externo (política de privacidad, "más cuentos", contacto) va SOLO en el panel
     del adulto, detrás de una puerta para padres: mantener apretado 3 s y resolver una consigna
     simple ("tocá los números del 1 al 3 en orden" con números escritos, no dibujos).
4. **Política de privacidad**: generá docs/privacy-policy.md (español e inglés), que diga
   la verdad: la app no recolecta, guarda en servidores ni comparte ningún dato; solo guarda
   ajustes y progreso en el dispositivo. Preparala para publicarla en una URL pública
   (GitHub Pages del repo, carpeta /docs).
5. **Seguridad de los datos**: escribí docs/play-data-safety.md con las respuestas del formulario
   de Play Console ("No se recolectan ni comparten datos").
6. **Tamaño**: el .aab tiene que quedar por debajo de 150 MB. Audio en .ogg Vorbis
   (voz mono 64 kbps, efectos y música 96 kbps), imágenes como SVG importado o WebP.
   Si a futuro con 8 cuentos se pasa, usar Play Asset Delivery; dejalo anotado, no lo implementes ahora.
7. **Ficha de la tienda**: script tools/store_assets que genere con capturas automáticas
   (escenas en headless + viewport): ícono de 512x512, gráfico destacado de 1024x500 y capturas
   horizontales de celular (1920x1080) y de tablet de 7" y 10". Textos de la ficha en
   docs/store-listing.md: título (máx. 30 caracteres), descripción breve (máx. 80) y completa,
   en español neutro latino.
8. **Versionado**: versionCode entero que sube en cada build; versionName semántico (0.1.0).
   Script tools/release.sh que exporte el .aab de release firmado.

## Pantallas
1. **Inicio (Library)**: la plaza del pueblo con el Árbol de las Puertas. Cada puerta es un cuento,
   leída de `res://stories/index.json`. Al tocar una puerta, la voz dice el título y se abre la
   portada de anticipación. Debajo de cada puerta, estrellas con los finales descubiertos.
   Las puertas con `"locked": true` aparecen cerradas con un cartel de "Próximamente".
   El árbol muestra las semillas de luz ganadas.
2. **Primer uso**: el adulto carga la edad del chico (3 a 12) y se sugiere el nivel de texto:
   simple de 3 a 5, cuento de 6 a 8 y aventura de 9 a 12. No se pide nombre ni ningún otro dato.
3. **StoryPlayer** (carga cualquier story.json):
   - El relato arranca SOLO al entrar a cada página, 300 ms después de terminar la transición
     (hoja que pasa en 400 ms; en modo calma, fundido).
   - Karaoke: resalta cada palabra según el JSON de tiempos.
   - Tocables: animación + sonido + palabra dicha ("¡Guau! Fido"). Mientras suena el efecto,
     el bus Voz baja a -8 dB. Ajuste opcional: bloquear los tocables hasta que termine el relato.
   - Pista de Lumi: después de 6 s sin tocar nada, Lumi brilla sobre un tocable.
   - Decisiones: 2 tarjetas grandes (imagen + texto + voz) cuando termina el relato. Sin límite
     de tiempo. Se puede volver atrás.
   - Flags: los tocables pueden activar marcas (huella_1..3). Una página puede desviar al
     final secreto si se cumplen las marcas requeridas.
   - P7, cierre común: vuelta al pueblo, Pipa planta la semilla y dice el mensaje.
     Después el chico puede elegir cómo se sintió (opcional) y aparecen los botones
     "Leer otra vez", "Probar otro camino" y "Volver a la plaza".
   - El progreso de la página actual se guarda: si la app se cierra, retoma donde estaba.
4. **Controles fijos** (siempre en el mismo lugar): Atrás, Siguiente, Repetir relato,
   Rincón de calma, Volver a la plaza e indicador con puntos ("3 de 7").
   El botón Atrás de Android vuelve una página, nunca cierra la app de golpe: en la plaza pide
   confirmación con un ícono.
5. **Rincón de calma**: pausa todo; Lumi respira (inflar 4 s / desinflar 4 s) con la voz guiando.
   Botón "Volver al cuento".
6. **Panel del adulto** (detrás de la puerta para padres): nivel de texto, volúmenes de Voz,
   Efectos y Música por separado, velocidad del relato (0.8/1/1.2), modo calma, subtítulos,
   bloqueo de tocables, giro por botón o por deslizamiento, tipografía de lectura fácil,
   edad, finales descubiertos por cuento, política de privacidad, "Borrar progreso" con confirmación.

## Accesibilidad (obligatoria)
- Zonas táctiles de 64 dp como mínimo; se ignoran los deslizamientos menores a 120 px.
- Nada de flashes, parpadeos, vibración ni sonidos fuertes repentinos.
  Todo el audio normalizado a -16 LUFS.
- Paleta suave, alto contraste entre texto y fondo, texto de 36 px o más.
- Ningún estado de "perder" ni límite de tiempo. Lenguaje literal: sin ironías ni metáforas.
- La app pausa el audio cuando pasa a segundo plano y lo retoma al volver.

## Audio y voces
- Buses: Master > Voz, Efectos, Música, con volúmenes guardados.
- tools/tts/: script en Python que lee story.json y genera cada .ogg de relato con Kokoro-82M
  (español neutro latino), más su JSON de tiempos por palabra. Opción configurable para usar
  Piper con voces es_MX. Si el motor no da tiempos, estimarlos por cantidad de sílabas.
  Los motores de TTS corren en mi PC; no se incluyen dentro de la app.
- Efectos de sonido: solo CC0 (Kenney, Freesound CC0). Registrá autor y licencia de cada uno en
  docs/credits.md.

## Datos de los cuentos
- `res://stories/<id>/story.json` + carpetas art/, vo/ y sfx/. Esquema en docs/story-schema.md,
  validado con JSON Schema. Texto en 3 niveles por página: simple, cuento y aventura.
- tools/validate.py: todos los caminos llegan a un final, no hay páginas sueltas, existen todos
  los archivos, cada decisión tiene 2 opciones y cada página tiene entre 3 y 5 tocables.
  Exporta el árbol del cuento en Mermaid a docs/trees/<id>.md.
- Guardado en user://save.json (ajustes, edad, finales, semillas, marcas, última página) con
  versión de esquema y migración. Escritura atómica (archivo temporal + rename).
- Textos de interfaz a través del sistema de traducción de Godot (es por defecto; dejá listo en).

## Contenido de prueba
1. `stories/dino` — "El huevo que brillaba" (van Pipa, Fido y Bubu), completo:
   P1 (la puerta verde se abre y rueda un huevo que brilla; el colgante se pone violeta),
   P2 (Fido sigue el rastro; decisión: por el río de las burbujas / por el bosque que canta),
   A3 (Tina, la triceratops bebé, los cruza en su lomo),
   A4 (cascada; decisión: subir paso a paso por las piedras / pedirle ayuda a Brachi),
   B3 (aparece Rex, enorme y tímido; el colgante se pone naranja; Bubu: "Tranqui… yo también soy
   grandote"; el colgante se pone verde),
   B4 (decisión: ir con Rex / ir solos y después presentarle a Rex),
   cuatro P5 y cuatro P6 (finales: "Paso a paso se llega lejos", "Pedir ayuda es de valientes",
   "Rex, el gigante bueno", "Hacer un amigo nuevo"), final secreto (con 3 huellas doradas
   escondidas en P1, A3 o B3 y P5, Pipa le enseña a volar al dinosaurio bebé) y P7 de cierre.
   Mensaje: "Lo distinto no da miedo cuando lo conocés."
   Los textos de los 3 niveles los escribís vos, con lenguaje literal y nombrando siempre
   la emoción de Pipa y el color del colgante.
   Personajes propios del cuento (Rex, Tina, Brachi, mamá Ptera) y fondos: placeholders con
   formas simples y su nombre. El elenco usa los SVG de Nido.
2. `stories/granja` — "El gallo que despertaba al sol" (van Pipa, Coco y Tati): solo P1 y P2,
   para probar que la plaza carga 2 cuentos.
3. Los otros 6 cuentos van en index.json como bloqueados:
   La selva que perdió su canción, Bolita y la ciudad de los relojes, El cofre de la abuela Tuga,
   Un amigo en la Luna, Las estrellas dormilonas, La gran fiesta del Árbol.

## Etapas
1. Repo, proyecto Godot, CI, copia del elenco desde Nido.
2. Esquema de datos + validador + tests.
3. StoryPlayer: páginas, transiciones, controles fijos.
4. Audio: buses, relato automático, karaoke, script de TTS.
5. Tocables, flags, pista de Lumi.
6. Decisiones, finales, final secreto, cierre con semilla.
7. Plaza (Library), primer uso, guardado y reanudación.
8. Panel del adulto con puerta para padres, Rincón de calma, colgante animado.
9. Export Android: .aab firmado, targetSdk 36, manifest sin permisos, prueba en dispositivo.
10. Material para Play: política de privacidad, seguridad de los datos, ficha de la tienda,
    capturas, docs/release.md con los pasos de Play Console (pista de prueba interna, después
    prueba cerrada y después producción).

Al terminar cada etapa: tests en verde, commit chico y un resumen de qué quedó y qué falta.
No digas "terminado" sin haberlo verificado.

## Criterio de terminado
En una tablet Android real, instalada desde la pista de prueba interna de Play:
se elige "El huevo que brillaba" en la plaza, el relato arranca solo al girar cada página,
se pueden recorrer los 4 finales y el secreto, los tocables responden, el colgante cambia de color,
la semilla aparece en el árbol, los ajustes y el progreso se guardan, la app no pide ningún permiso,
el validador pasa y el .aab de release sube a Play Console sin errores de targetSdk ni de política.
