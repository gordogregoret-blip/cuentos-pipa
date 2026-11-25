# Publicar en Google Play

Guía paso a paso para generar el `.aab` firmado y llevarlo de la prueba interna a producción.

## 0. Una sola vez: preparar la computadora

```bash
tools/setup_godot.sh --templates
```

```bash
tools/setup_android.sh
```

`setup_godot.sh` descarga Godot 4.7 y sus plantillas de exportación. `setup_android.sh` instala
el Android SDK (plataforma 36, build-tools 36.1.0, NDK) y le dice al editor de Godot dónde está.
Hace falta Java 17 o más nuevo (`java -version`).

## 1. Una sola vez: crear la upload key

Google Play usa **Play App Signing**: Google guarda la clave con la que se firma la app que llega a
los teléfonos, y vos firmás cada subida con una **upload key** propia. Si perdés la upload key, se
puede pedir a Google que la reemplace. Igual, guardala con cuidado.

```bash
mkdir -p ~/.keystores
```

```bash
keytool -genkeypair -v -keystore ~/.keystores/cuentos-pipa-upload.jks -alias upload -keyalg RSA -keysize 4096 -validity 10000
```

**El keystore y las contraseñas NUNCA van al repo.** El `.gitignore` ya excluye `*.keystore`,
`*.jks`, `.env` y `release.env`, y `tools/release.sh` se niega a usar un keystore que esté adentro
del repo.

Creá un archivo `release.env` en la raíz del repo (está ignorado por git):

```bash
cat > release.env <<'EOF'
GODOT_ANDROID_KEYSTORE_RELEASE_PATH=/home/TU_USUARIO/.keystores/cuentos-pipa-upload.jks
GODOT_ANDROID_KEYSTORE_RELEASE_USER=upload
GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=la-contraseña-que-elegiste
EOF
```

Hacé una copia de seguridad del `.jks` y de la contraseña fuera de la computadora, por ejemplo en
un gestor de contraseñas.

## 2. Cada versión: generar el .aab

```bash
tools/release.sh
```

El script hace todo esto:
1. Sube `version/code` en 1. Play exige que crezca en cada subida.
2. Corre el validador de cuentos.
3. Exporta `build/android/cuentos-pipa.aab` con Gradle, firmado con la upload key.
4. Corre `tools/check_aab.sh`, que verifica:
   - que no se pide ningún permiso;
   - que targetSdk es 36 y minSdk es 24;
   - que vienen las dos arquitecturas (arm64-v8a y armeabi-v7a);
   - que pesa menos de 150 MB;
   - que está firmado.

Para cambiar el número de versión visible (semántico):

```bash
tools/release.sh --name 0.2.0
```

Hacé commit del `export_presets.cfg` con el nuevo `version/code` después de cada subida.

### Voces

Antes de una versión, regenerá las voces si cambió algún texto (ver `tools/tts/README.md`):

```bash
python3 tools/tts/tts.py --story stories/dino --engine kokoro --force
```

## 3. Política de privacidad pública (GitHub Pages)

La política está en `docs/privacy-policy.md` y se publica con GitHub Pages:

1. El contacto de la política apunta a los *issues* del repo y al correo de la ficha de Play (que se completa en Play Console, no en el repo).
2. En GitHub: **Settings → Pages → Build and deployment → Deploy from a branch → `main` / `/docs`**.
   Con el plan gratuito de GitHub, Pages funciona en repositorios **públicos**. Si el repo es
   privado, hace falta un plan pago o publicar la política en otro lugar.
3. La URL queda en `https://gordogregoret-blip.github.io/cuentos-pipa/privacy-policy`. Es la misma
   que usan `src/core/Links.gd` y la ficha de Play.

## 4. Play Console: crear la app

1. **Crear app**: nombre “Cuentos de Pipa”, idioma predeterminado español (Latinoamérica),
   tipo **App**, **Paga**.
   Ojo: una app que se publica paga no se puede pasar a gratuita después, y al revés tampoco.
2. **Contenido de la app**: completá cada formulario con `docs/play-data-safety.md`:
   - política de privacidad;
   - anuncios;
   - público objetivo (incluye menores de 13, así que se aplica la Política de Familias);
   - clasificación de contenido;
   - seguridad de los datos.
3. **Ficha de Play Store**: textos de `docs/store-listing.md` y gráficos de `store/`
   (ícono 512, gráfico destacado 1024×500, capturas de celular y de tablets de 7" y 10").
4. **Precio**: en *Monetizar → Productos → Precio de la app*. Para cobrar hace falta tener
   configurado el **perfil de pagos**.

## 5. Pistas: interna → cerrada → producción

### Prueba interna (hasta 100 testers, disponible en minutos)

1. *Probar y publicar → Pruebas → Prueba interna → Crear versión*.
2. Aceptá **Play App Signing** la primera vez.
3. Subí `build/android/cuentos-pipa.aab`. Play Console revisa el targetSdk y la política en este paso.
4. En *Testers* creá una lista de correos y copiá el **enlace para unirse**.
5. Desde la tablet, con una de esas cuentas, abrí el enlace, aceptá y descargá desde Play.

**Lista para probar en la tablet** (criterio de terminado):

- [ ] Al instalar, Android no pide ningún permiso.
- [ ] Primer uso: se elige la edad y se sugiere el nivel.
- [ ] En la plaza se ven 8 puertas: 2 abiertas y 6 con “Próximamente”.
- [ ] Al tocar “El huevo que brillaba”, la voz dice el título y aparece la portada.
- [ ] El relato arranca solo cada vez que se gira la hoja y las palabras se resaltan.
- [ ] Los tocables responden (animación, sonido y palabra) y Lumi aparece después de 6 s.
- [ ] El colgante cambia de color y la voz lo nombra.
- [ ] Se recorren los 4 finales: paso a paso, pedir ayuda, Rex el gigante bueno, amigo nuevo.
- [ ] Con las 3 huellas doradas (P1, A3 o B3, y P5) se llega al final secreto.
- [ ] En P7 aparece la semilla. De vuelta en la plaza, la semilla está en el árbol y hay estrellas
      bajo la puerta.
- [ ] Cerrar la app a mitad de un cuento y volver a abrirla ofrece “Seguir donde estaba”.
- [ ] El botón Atrás de Android vuelve una página. En la plaza pregunta antes de salir.
- [ ] Rincón de calma: Lumi respira 4 s y 4 s, y “Volver al cuento” vuelve a leer la página.
- [ ] Panel de adultos: mantener 3 s, tocar 1-2-3. Cada ajuste se guarda al cerrar y volver a abrir.
- [ ] Al pasar a segundo plano el audio se pausa, y al volver sigue.
- [ ] Se ve bien en horizontal en tablet (4:3 o 16:10) y en un celular 20:9.

### Prueba cerrada (obligatoria para cuentas personales nuevas)

Las cuentas de desarrollador **personales** creadas después de noviembre de 2023 tienen que hacer
una prueba cerrada con al menos **12 testers durante 14 días seguidos** antes de pedir acceso a
producción. Las cuentas de organización no tienen este requisito.

1. *Pruebas → Prueba cerrada → Crear pista* y subí el mismo `.aab` (o uno nuevo con `tools/release.sh`).
2. Invitá a los testers por lista de correos o Grupo de Google.
3. Cuando se cumplan los 14 días, *Panel → Solicitar acceso a producción*.

### Producción

1. *Producción → Crear versión*, elegí el `.aab` de la prueba cerrada y escribí las notas de la versión.
2. Enviá a revisión. Las apps para chicos pueden tardar más, porque Google revisa la Política de Familias.
3. Si hace falta, usá un lanzamiento gradual (por ejemplo 20 % y después 100 %).

## Tamaño y crecimiento

El `.aab` de hoy pesa pocos MB. Con 8 cuentos completos (voces de 3 niveles, efectos y arte final)
puede crecer. Si `check_aab.sh` avisa que pasa los 150 MB, hay que mover las voces de cada cuento a
**Play Asset Delivery** (packs *install-time* o *on-demand*, uno por cuento). No está implementado
todavía: es la mejora prevista para cuando haga falta.

## Si algo falla

| Problema | Solución |
|---|---|
| “Falta GODOT_ANDROID_KEYSTORE_RELEASE_…” | Revisá `release.env` (paso 1). |
| Gradle no encuentra el SDK | Corré `tools/setup_android.sh` de nuevo. |
| Play rechaza el versionCode | Ya subiste ese número: corré `tools/release.sh` otra vez (sube el número). |
| Play pide targetSdk más alto | Cambiá `gradle_build/target_sdk` en `export_presets.cfg` y el test de `tools/tests/test_release.py`. |
