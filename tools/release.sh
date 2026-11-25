#!/usr/bin/env bash
# Exporta el .aab de release FIRMADO con la upload key y lo revisa.
#
# La clave y las contraseñas NUNCA van al repo. Se leen de variables de entorno
# (las mismas que usa Godot) o de un archivo release.env ignorado por git:
#   GODOT_ANDROID_KEYSTORE_RELEASE_PATH=/ruta/fuera/del/repo/upload.keystore
#   GODOT_ANDROID_KEYSTORE_RELEASE_USER=upload
#   GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=********
#
# Uso: tools/release.sh [--name 0.2.0] [--no-bump]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
[[ -f release.env ]] && set -a && source release.env && set +a
for v in GODOT_ANDROID_KEYSTORE_RELEASE_PATH GODOT_ANDROID_KEYSTORE_RELEASE_USER GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD; do
  [[ -n "${!v:-}" ]] || { echo "Falta $v (ver docs/release.md)"; exit 1; }
done
[[ -f "$GODOT_ANDROID_KEYSTORE_RELEASE_PATH" ]] || { echo "No existe el keystore $GODOT_ANDROID_KEYSTORE_RELEASE_PATH"; exit 1; }
case "$GODOT_ANDROID_KEYSTORE_RELEASE_PATH" in "$ROOT"/*) echo "El keystore no puede estar dentro del repo"; exit 1;; esac

GODOT="${GODOT:-$(command -v godot || echo "$ROOT/.tools/bin/godot")}"
BUMP=1; NAME=""
while [[ $# -gt 0 ]]; do
  case "$1" in --no-bump) BUMP=0;; --name) NAME="$2"; shift;; esac; shift
done
if (( BUMP )); then
  code=$(python3 tools/bump_version.py ${NAME:+--name "$NAME"})
  echo "versionCode → $code"
fi

python3 tools/validate.py stories
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
mkdir -p build/android
TEMPLATE=""
[[ -d android/build ]] || TEMPLATE="--install-android-build-template"
"$GODOT" --headless --path . $TEMPLATE --export-release "Android" build/android/cuentos-pipa.aab
tools/check_aab.sh build/android/cuentos-pipa.aab
echo "Listo: build/android/cuentos-pipa.aab (subilo a Play Console → Prueba interna)"
