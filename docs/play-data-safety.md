# Play Console — Seguridad de los datos y contenido de la app

Respuestas para los formularios de **Play Console → Contenido de la app**. Todas coinciden con
`docs/privacy-policy.md` y con el código (sin permisos, sin red, sin SDKs).

## Seguridad de los datos (Data safety)

| Pregunta | Respuesta |
|---|---|
| ¿Tu app recopila o comparte alguno de los tipos de datos de usuario obligatorios? | **No** |
| ¿Todos los datos de usuario que recopila tu app están encriptados en tránsito? | No corresponde (no se transmite nada) |
| ¿Ofreces a los usuarios una forma de solicitar que se borren sus datos? | No corresponde (no se recopilan datos). Igualmente, la app tiene “Borrar progreso” en el panel de adultos, y desinstalarla borra todo. |

Resultado que muestra la ficha: **“No se recopilan datos” y “No se comparten datos con terceros”.**

Notas para quien completa el formulario:
- Guardar ajustes y progreso **solo en el dispositivo** no cuenta como “recopilación”: Google define
  recopilar como transmitir datos fuera del dispositivo.
- La edad que carga el adulto queda en el dispositivo y no se transmite.
- No hay SDKs de terceros que recopilen datos (sin analíticas, anuncios ni reportes de errores).

## Público objetivo y contenido (Target audience)

| Pregunta | Respuesta |
|---|---|
| Grupos de edad | **5 años o menos**, **6 a 8 años**, **9 a 12 años** |
| ¿La app podría atraer sin querer a niños? | Sí, está hecha para niños |
| Política de Familias | Se acepta y se cumple (ver abajo) |

## Cumplimiento de la Política de Familias

- Sin anuncios y sin SDKs publicitarios.
- Sin compras dentro de la app.
- Sin ubicación, sin identificadores del dispositivo (ni ID de publicidad, ni Android ID), sin datos personales.
- Sin enlaces a redes sociales.
- Enlaces externos solo en el panel de adultos, detrás de la puerta para padres.
- Sin permisos de Android (el manifest no declara ningún `uses-permission`).

## Otras declaraciones de Contenido de la app

| Formulario | Respuesta |
|---|---|
| Anuncios | La app **no contiene anuncios** |
| Acceso a la app | Toda la funcionalidad está disponible sin restricciones especiales. El panel de adultos se abre manteniendo apretado el botón 3 segundos y tocando 1, 2, 3 en orden. |
| Clasificación del contenido (IARC) | Categoría “Referencia, noticias o educación”. Sin violencia, sin miedo intenso, sin lenguaje inapropiado, sin interacción entre usuarios, sin compras, sin ubicación. Resultado esperado: apto para todo público (PEGI 3 / ESRB Everyone). |
| ID de publicidad | La app **no usa** el ID de publicidad |
| App de noticias | No |
| App gubernamental | No |
| Funciones financieras | Ninguna |
| Salud | No es una app de salud |
| Política de privacidad | https://gordogregoret-blip.github.io/cuentos-pipa/privacy-policy |
