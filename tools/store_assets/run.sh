#!/usr/bin/env bash
# Genera los recursos gráficos para la ficha de Google Play en store/:
#   ícono 512×512, gráfico destacado 1024×500, capturas de celular (1920×1080),
#   tablet de 7" (1920×1200) y tablet de 10" (2560×1600).
# Usa Godot con un servidor X virtual (xvfb) para renderizar las escenas reales.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
GODOT="${GODOT:-$(command -v godot || echo "$ROOT/.tools/bin/godot")}"
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --headless --path . -s tools/store_assets/make_icons.gd

shot() {  # shot <WxH> <out.png> <args...>
  local size="$1" out="$2"; shift 2
  xvfb-run -a -s "-screen 0 ${size}x24" "$GODOT" --path . --display-driver x11 --rendering-driver opengl3 \
    --resolution "$size" res://tools/store_assets/Capture.tscn -- --out "$out" "$@" 2>&1 | grep -E "^captura" || true
}

SCENES=(
  "01_plaza|--scene library --seeds 3 --endings paso_a_paso,rex_gigante_bueno --wait 2"
  "02_huevo|--scene story --page p1 --wait 2.4 --level cuento"
  "03_rex|--scene story --page b3 --step 3 --wait 3 --level cuento"
  "04_decision|--scene story --page p2 --step 2 --cards 1 --wait 2.2 --level cuento"
  "05_lumi|--scene story --page a3 --step 3 --hint 1 --wait 2.4 --level simple"
  "06_cierre|--scene closing --page p7 --step 7 --wait 2.4"
  "07_calma|--scene calm --wait 2.6"
  "08_adultos|--scene adult --wait 1.6"
)
for kind in phone:1920x1080 tablet7:1920x1200 tablet10:2560x1600; do
  name="${kind%%:*}"; size="${kind##*:}"
  mkdir -p "store/screenshots/$name"
  for s in "${SCENES[@]}"; do
    shot "$size" "store/screenshots/$name/${s%%|*}.png" ${s#*|}
  done
done
mkdir -p store/feature
shot 2048x1000 build/feature_2048.png --scene feature --wait 1.5
convert build/feature_2048.png -resize 1024x500! store/feature/feature_1024x500.png
echo "Listo: store/"
