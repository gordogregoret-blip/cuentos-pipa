# Cuentos del pueblo de Pipa — plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** App Godot 4.7 para Android con cuentos interactivos guiados por datos, lista para la pista de prueba interna de Play.

**Architecture:** Los cuentos son `story.json` validados por JSON Schema. La lógica (grafo, marcas, guardado, puerta para padres, karaoke, deslizamiento, zonas seguras) vive en clases `RefCounted` probadas con GUT. Las escenas solo muestran. Herramientas en Python (`tools/`) probadas con pytest. El CI corre todo.

**Tech Stack:** Godot 4.7 (gl_compatibility), GDScript tipado, GUT 9.6.1, Python 3 + jsonschema + pytest, ffmpeg (ogg Vorbis), bundletool, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-11-25-cuentos-pipa-design.md` + `docs/superpowers/specs/2026-11-25-pedido-original.md`

## Global Constraints

- Godot 4.7, `gl_compatibility`, `sensor_landscape`, base 1920x1080, stretch `canvas_items`, aspect `expand`.
- Sin SDKs de terceros, sin INTERNET ni ningún otro permiso en el manifest.
- targetSdk 36, minSdk 24, arm64-v8a + armeabi-v7a, .aab con Gradle build, < 150 MB.
- Zonas táctiles ≥ 64 dp; deslizamientos < 120 px se ignoran; texto ≥ 36 px.
- Sin flashes, parpadeos, vibración, sonidos fuertes; audio normalizado a -16 LUFS.
- Voz mono 64 kbps, efectos y música 96 kbps, ogg Vorbis.
- Relato arranca 300 ms después de la transición (hoja 400 ms; modo calma: fundido).
- Mientras suena un efecto, el bus Voz baja a -8 dB. Pista de Lumi tras 6 s sin tocar.
- Edad 3-5 → simple, 6-8 → cuento, 9-12 → aventura.
- Puerta para padres: mantener 3 s + tocar 1, 2, 3 en orden (números escritos).
- Nada de emoji ni OpenMoji. Paleta y reglas: `docs/art/art-direction-brief.md`.
- Textos de UI vía `tr()`; es por defecto, en listo.
- Keystore y contraseñas nunca en el repo.

## Review Focus

1. `save.json` corrupto o a medio escribir → se cargan valores por defecto, sin crash (test en Task 7).
2. Reanudación que apunta a una página que ya no existe → arranca en la primera página (Task 7).
3. Toques repetidos en Siguiente o en una decisión durante la transición → un solo cambio de página (Task 5).
4. Botón Atrás de Android con Rincón de calma, panel o puerta abiertos → cierra la capa, no cambia de página (Task 10).
5. App en segundo plano durante el relato → el relato y el karaoke siguen desde donde estaban y la pista de Lumi no salta (Task 6).

---

## Estructura de archivos

```
project.godot, export_presets.cfg, default_bus_layout.tres, .gutconfig.json, icon.svg
addons/gut/                     copia de Nido (9.6.1)
art/cast/*.svg, art/cast/shared/*.svg   elenco de Nido
art/ui/*.svg                    Lumi, colgante, puerta, árbol, semillas, íconos de controles
fonts/                          Nunito (texto), Atkinson Hyperlegible (lectura fácil) — OFL
locale/ui.csv                   es, en
schema/story.schema.json
src/core/   StoryData, StoryState, StoryIndex, SaveData, Levels, KaraokeTimeline,
            SwipeDetector, SafeArea, ParentGateLogic, Pendant, BreathCycle, HintTimer
src/autoload/  Store.gd (guardado), Audio.gd (buses, ducking, pausa)
src/cast/   CharacterDefs.gd, CharacterRig.gd (adaptados de Nido)
src/ui/     Library, Cover, FirstRun, StoryPlayer, PageView, Controls, Tappable, Narrator,
            DecisionCards, Closing, CalmCorner, ParentGate, AdultPanel, ConfirmExit
stories/index.json, stories/dino/, stories/granja/
test/unit/*.gd, test/fixtures/stories/mini/
tools/validate.py, tools/tts/, tools/art/placeholders.py, tools/sfx/make_sfx.py,
tools/store_assets/, tools/release.sh, tools/bump_version.py, tools/setup_android.sh,
tools/setup_godot.sh, tools/check_aab.sh, tools/tests/*.py
docs/…   (personajes, brief, story-schema, privacy-policy, play-data-safety, store-listing,
          release, credits, trees/)
.github/workflows/ci.yml
```

## Formato de story.json (decisión central)

```json
{
  "schema": 1, "id": "dino", "title": "El huevo que brillaba", "cast": ["pipa","fido","bubu"],
  "message": "Lo distinto no da miedo cuando lo conocés.", "start": "p1",
  "preview": false,
  "secret": {"requires": ["huella_1","huella_2","huella_3"], "page": "s6"},
  "pages": {
    "p1": {
      "background": "art/bg_plaza.svg",
      "text": {"simple": "…", "cuento": "…", "aventura": "…"},
      "pendant": [{"color": "violeta", "at": 0.5}],
      "characters": [{"id": "pipa", "x": 0.25, "y": 0.85, "scale": 0.6}],
      "tappables": [{"id": "huevo", "art": "art/huevo.svg", "x": 0.5, "y": 0.6, "size": 220,
                     "anim": "bounce", "sfx": "sfx/brillo.ogg", "word": "¡Brilla! El huevo",
                     "flag": "huella_1"}],
      "next": "p2"
    }
  }
}
```

- Una página tiene exactamente una salida: `next` (id), `decision` (`{"options":[{"text","image","to"}×2]}`) o `closing: true` (P7). `ending: {"id","title"}` marca un final; `secret_next` va en cada P5.
- `characters[].id` es un id del elenco (`pipa|sofi|bubu|fido|tati`) o un archivo `art/*.svg`.
- `art` de un tocable puede ser `cast:<id>`.
- Archivos de voz por convención, no se listan: `vo/<page>_<level>.ogg` + `.json` (tiempos),
  `vo/<page>_tap_<id>.ogg`, `vo/<page>_opt<n>.ogg`, `vo/title.ogg`, `vo/message.ogg`.
- Tiempos: `[{"w": "Pipa", "t0": 0.0, "t1": 0.42}, …]` en segundos.
- Cuento `preview: true` (granja): se permite una página con `next: null`, sin finales ni decisiones obligatorias.

---

### Task 1: Proyecto Godot, GUT, CI (Etapa 1)

**Files:** `project.godot`, `.gutconfig.json`, `.gitignore`, `icon.svg`, `addons/gut/`, `tools/setup_godot.sh`, `.github/workflows/ci.yml`, `test/unit/test_project_settings.gd`, `README.md`

- [ ] Test `test_project_settings.gd`: asserts en `ProjectSettings` → viewport 1920x1080, stretch `canvas_items`, aspect `expand`, orientación `sensor_landscape` (valor 6), renderer `gl_compatibility`, main scene seteada.
- [ ] Correr `godot --headless -s addons/gut/gut_cmdln.gd -gexit` → falla. Crear `project.godot` → pasa.
- [ ] `.gitignore`: `.godot/`, `*.keystore`, `*.jks`, `.env`, `release.env`, `build/`, `.tools/`.
- [ ] CI: jobs `python` (pytest tools/tests, validate.py) y `godot` (setup_godot.sh, `--import`, GUT).
- [ ] Commit.

### Task 2: Elenco desde Nido (Etapa 1)

**Files:** `art/cast/**`, `src/cast/CharacterDefs.gd`, `src/cast/CharacterRig.gd`, `docs/personajes.md`, `docs/art/art-direction-brief.md`, `test/unit/test_cast.gd`

**Interfaces — Produces:** `CharacterRig.new()`, `rig.setup(id: String)`, `rig.set_state(&"idle"|&"talk"|&"happy"|&"sad")`, `CharacterDefs.CAST_IDS = {"pipa":"pipa","sofi":"coneja","bubu":"oso","fido":"perro","tati":"gato"}`.

- [ ] Test: por cada id de `CAST_IDS`, `all_textures(id)` existe en `res://art/cast/` y los offsets coinciden con el viewBox de cada SVG.
- [ ] Copiar SVG (sin `.import`), adaptar rutas y quitar lo propio del café. Escribir `personajes.md`.
- [ ] Tests en verde, commit.

### Task 3: Esquema + validador + Mermaid (Etapa 2)

**Files:** `schema/story.schema.json`, `tools/validate.py`, `tools/tests/test_validate.py`, `tools/tests/fixtures/`, `docs/story-schema.md`

**Produces:** `validate_story(path) -> list[str]` (errores), `validate_all(root) -> int` (CLI, exit≠0 si hay errores), `mermaid(story) -> str`; `python3 tools/validate.py stories --trees docs/trees`.

- [ ] Tests (pytest, un fixture válido + mutaciones): esquema inválido; página inalcanzable ("página suelta"); camino sin final (ciclo); decisión con ≠2 opciones; página con 2 o 6 tocables; archivo faltante (fondo, sfx, vo por convención); `to` a página inexistente; marca de `secret.requires` que ningún tocable activa; preview acepta `next: null`; mermaid contiene `p1 --> p2` y `p2 -->|…| a3`.
- [ ] Implementar. Commit.

### Task 4: StoryData + StoryState (Etapa 2)

**Files:** `src/core/StoryData.gd`, `src/core/StoryState.gd`, `src/core/Levels.gd`, `test/fixtures/stories/mini/`, `test/unit/test_story_state.gd`, `test/unit/test_levels.gd`

**Produces:**
- `StoryData.load_from(dir: String) -> StoryData` (null si falla); `.page(id) -> Dictionary`; `.text(id, level: StringName) -> String`; `.vo_path(id, level) -> String`; `.timings_path(id, level)`.
- `StoryState.new(data)`: `current: String`, `history: Array[String]`, `flags: Array[String]`, `start()`, `go_next() -> bool`, `choose(i: int) -> bool`, `back() -> bool` (false en la primera), `set_flag(f)`, `step() -> int` (history.size()+1), `kind() -> StringName` (`&"next"|&"decision"|&"closing"|&"end_preview"`), `to_dict()`, `from_dict(data, d) -> bool` (false si la página no existe).
- `Levels.for_age(age: int) -> StringName`.

- [ ] Tests: start→p1; go_next en página con decisión devuelve false; choose(1) va a la opción 2; back vuelve y quita de history; P5 con las 3 marcas → `s6`, sin ellas → su P6; marcas sin repetir; `from_dict` con página inexistente → false; `Levels.for_age(3)=&"simple"`, `5→simple`, `6→cuento`, `8→cuento`, `9→aventura`, `12→aventura`.
- [ ] Implementar. Commit.

### Task 5: StoryPlayer, transiciones, controles (Etapa 3)

**Files:** `src/core/SwipeDetector.gd`, `src/core/SafeArea.gd`, `src/ui/StoryPlayer.tscn/.gd`, `src/ui/PageView.gd`, `src/ui/Controls.tscn/.gd`, `locale/ui.csv`, `fonts/`, `test/unit/test_swipe.gd`, `test/unit/test_safe_area.gd`, `test/unit/test_story_player.gd`

**Produces:** `StoryPlayer.open(story_dir, resume := {})`, signals `page_shown(id)`, `transition_finished`, `exit_requested`; `is_transitioning() -> bool`; `TURN_TIME := 0.4`, `NARRATION_DELAY := 0.3`.

- [ ] Tests: swipe de 119 px → nada, 120 px a la izquierda → `&"next"`; `SafeArea.margins(Rect2i(80,0,1840,1080), Vector2i(2000,1080))` → izquierda 80, derecha 80; dos `go_next` seguidos durante la transición → un solo `page_shown`; indicador muestra "3 de 7"; en modo calma la transición es fundido; botones ≥ 64 dp (≥ 96 px en la base).
- [ ] Implementar (hoja: `Tween` de escala/rotación sobre un recorte del viewport; calma: `modulate.a`). Commit.

### Task 6: Audio, relato, karaoke, TTS (Etapa 4)

**Files:** `default_bus_layout.tres`, `src/autoload/Audio.gd`, `src/core/KaraokeTimeline.gd`, `src/ui/Narrator.gd`, `tools/tts/tts.py`, `tools/tts/engines.py`, `tools/tts/syllables.py`, `tools/tts/README.md`, `tools/tests/test_tts.py`, `test/unit/test_audio.gd`, `test/unit/test_karaoke.gd`

**Produces:** `Audio.play_voice(path) -> void`, `Audio.play_sfx(path)`, `Audio.set_bus_volume(bus: StringName, linear: float)`, `Audio.set_speed(s: float)` (pitch shift compensado en Voz), `Audio.pause_all()/resume_all()`, signal `voice_finished`; `KaraokeTimeline.new(timings, speed).index_at(t: float) -> int`; `Narrator.narrate(text, vo, timings)`, signals `word(i)`, `finished`.

- [ ] Tests GDScript: buses `Master, Voz, Efectos, Musica`; durante sfx el Voz queda en -8 dB y vuelve; `index_at` antes de la primera palabra → -1, en el medio → la palabra correcta, con velocidad 1.2 los tiempos se dividen por 1.2; `pause_all` congela el tiempo del narrador y la pista (Review Focus 5).
- [ ] Tests pytest: `count_syllables("murciélago")==4`, `"Pipa"==2`, `"guau"==1`; `estimate_timings` es monótona y suma la duración; los nombres de archivo siguen la convención; `--engine placeholder` escribe ogg + json para el fixture.
- [ ] `tts.py --story DIR --engine {kokoro,piper,placeholder}`: Kokoro (`kokoro` pip, voz `ef_dora`, lang `e`), Piper (`es_MX-claude-high`); loudnorm -16 LUFS, mono 64k.
- [ ] Commit.

### Task 7: Guardado (Etapa 7, adelantado porque lo usa todo)

**Files:** `src/core/SaveData.gd`, `src/autoload/Store.gd`, `test/unit/test_save.gd`

**Produces:** `SaveData.SCHEMA := 1`, `SaveData.defaults() -> Dictionary`, `SaveData.migrate(d) -> Dictionary`, `SaveData.write_atomic(path, d) -> bool`, `SaveData.read(path) -> Dictionary`; `Store.data`, `Store.save()`, `Store.settings(key)`, `Store.record_ending(story, id)`, `Store.add_seed(story)`, `Store.set_resume(story, state_dict)`, `Store.clear_progress()`.

- [ ] Tests: archivo inexistente → defaults; basura → defaults (Review Focus 1); v0 (sin `schema`, con `volumen`) → migra a v1 conservando el valor; escritura atómica deja solo `save.json` (sin `.tmp`); final repetido no se duplica; semilla una sola vez por cuento; `clear_progress` conserva ajustes y edad; reanudación a página inexistente → empieza de cero (Review Focus 2).
- [ ] Commit.

### Task 8: Tocables, marcas, Lumi, colgante (Etapa 5)

**Files:** `src/ui/Tappable.gd`, `src/core/HintTimer.gd`, `src/core/Pendant.gd`, `src/ui/PendantView.gd`, `art/ui/lumi.svg`, `art/ui/colgante.svg`, `test/unit/test_tappable.gd`, `test/unit/test_pendant.gd`

**Produces:** `Tappable.setup(def, story_dir)`, signal `tapped(def)`; `HintTimer.new(6.0)`, `.tick(dt) -> bool`, `.touch()`; `Pendant.COLORS` (amarillo, azul, rojo, violeta, verde, naranja → `Color`), `Pendant.EMOTION` (contenta, triste, enojada, sorprendida, tranquila, con miedo).

- [ ] Tests: tocar activa la marca una vez; con bloqueo activado no responde hasta el final del relato; `HintTimer` dispara a los 6.0 s y no a los 5.9, `touch()` reinicia; colores exactos; frase "El colgante está azul. Pipa está triste.".
- [ ] Commit.

### Task 9: Decisiones, finales, secreto, cierre (Etapa 6)

**Files:** `src/ui/DecisionCards.gd`, `src/ui/Closing.gd`, `test/unit/test_flow.gd`

- [ ] Tests (mini fixture): las tarjetas aparecen solo después de `Narrator.finished`; elegir registra el camino; entrar a una página con `ending` registra el final en Store; en P7 se agrega la semilla, aparecen el selector de emoción y los 3 botones; "Leer otra vez" → p1 con marcas limpias; "Probar otro camino" → última decisión; "Volver a la plaza" → `exit_requested`.
- [ ] Commit.

### Task 10: Plaza, portada, primer uso, Atrás de Android (Etapa 7)

**Files:** `src/core/StoryIndex.gd`, `src/ui/Library.gd`, `src/ui/Cover.gd`, `src/ui/FirstRun.gd`, `src/ui/ConfirmExit.gd`, `src/Main.gd`, `test/unit/test_library.gd`, `test/unit/test_back.gd`

- [ ] Tests: el índice carga 8 entradas, 2 abiertas y 6 bloqueadas; estrellas = finales descubiertos; puerta bloqueada muestra "Próximamente" y no abre; sin edad → primer uso; el primer uso sugiere el nivel según la edad; Atrás en la plaza → confirmación; Atrás con capa abierta → cierra la capa (Review Focus 4); con reanudación → la portada ofrece "Seguir".
- [ ] Commit.

### Task 11: Puerta para padres, panel del adulto, Rincón de calma (Etapa 8)

**Files:** `src/core/ParentGateLogic.gd`, `src/core/BreathCycle.gd`, `src/ui/ParentGate.gd`, `src/ui/AdultPanel.gd`, `src/ui/CalmCorner.gd`, `test/unit/test_parent_gate.gd`, `test/unit/test_breath.gd`, `test/unit/test_adult_panel.gd`

- [ ] Tests: soltar a los 2.9 s → no avanza; a los 3.0 s pasa a la consigna; 1-2-3 → abre, 1-3 → reinicia la secuencia sin mensaje de error; `BreathCycle.phase_at(0..4) = &"in"`, `(4..8) = &"out"`, escala 1.0→1.4; cada control del panel escribe en Store; "Borrar progreso" pide confirmación; el Rincón de calma pausa el audio y "Volver al cuento" lo retoma.
- [ ] Commit.

### Task 12: Contenido: dino, granja, índice, arte provisorio, efectos (Etapa 6/7)

**Files:** `stories/index.json`, `stories/dino/**`, `stories/granja/**`, `tools/art/placeholders.py`, `tools/sfx/make_sfx.py`, `docs/credits.md`, `docs/trees/*.md`

- [ ] Escribir `dino/story.json`: 18 páginas (p1, p2, a3, a4, b3, b4, 4×p5, 4×p6, s6, p7), 3 niveles, cada página con 3-5 tocables, colgante nombrado. Huellas en p1, a3/b3 y cada p5.
- [ ] Arte provisorio SVG (formas + nombre) con la paleta; efectos sintetizados y normalizados; voces provisorias con `tts.py --engine placeholder`.
- [ ] `python3 tools/validate.py stories --trees docs/trees` → 0 errores. Commit.

### Task 13: Export Android (Etapa 9)

**Files:** `export_presets.cfg`, `tools/setup_android.sh`, `tools/bump_version.py`, `tools/release.sh`, `tools/check_aab.sh`, `tools/tests/test_bump_version.py`

- [ ] Test pytest: `bump_version` sube `version/code` en 1 y conserva `version/name`.
- [ ] Preset: Gradle, aab, min 24, target 36, archs, todos los permisos en false, `package/unique_name=com.pueblodepipa.cuentos`.
- [ ] `release.sh`: lee `GODOT_ANDROID_KEYSTORE_RELEASE_*` de `release.env` (ignorado por git), sube la versión y exporta. `check_aab.sh`: bundletool → sin `uses-permission`, targetSdk 36, tamaño < 150 MB.
- [ ] Generar el .aab con una clave de prueba y correr `check_aab.sh`. Commit.

### Task 14: Material para Play (Etapa 10)

**Files:** `docs/privacy-policy.md`, `docs/index.md`, `docs/_config.yml`, `docs/play-data-safety.md`, `docs/store-listing.md`, `docs/release.md`, `tools/store_assets/capture.gd`, `tools/store_assets/run.sh`, `tools/tests/test_store_listing.py`, `store/`

- [ ] Test: título ≤ 30 caracteres, descripción breve ≤ 80, completa ≤ 4000.
- [ ] Capturas con xvfb: ícono 512, gráfico destacado 1024x500, celular 1920x1080, tablet de 7" (1920x1200) y de 10" (2560x1600).
- [ ] Commit, push y resumen final.
