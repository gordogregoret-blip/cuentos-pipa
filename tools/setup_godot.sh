#!/usr/bin/env bash
# Descarga Godot 4.7 (Linux, headless-capable) a .tools/ y deja `godot` en PATH vía .tools/bin.
# Uso: source <(tools/setup_godot.sh --env)   o   tools/setup_godot.sh [--templates]
set -euo pipefail
VERSION="4.7"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/.tools/godot-$VERSION"
BIN="$DEST/Godot_v${VERSION}-stable_linux.x86_64"
BASE="https://github.com/godotengine/godot/releases/download/${VERSION}-stable"

if [[ "${1:-}" == "--env" ]]; then echo "export PATH=\"$ROOT/.tools/bin:\$PATH\""; exit 0; fi

if [[ ! -x "$BIN" ]]; then
  mkdir -p "$DEST"
  curl -fsSL -o "$DEST/godot.zip" "$BASE/Godot_v${VERSION}-stable_linux.x86_64.zip"
  unzip -oq "$DEST/godot.zip" -d "$DEST" && rm "$DEST/godot.zip"
fi
mkdir -p "$ROOT/.tools/bin"
ln -sf "$BIN" "$ROOT/.tools/bin/godot"

if [[ "${1:-}" == "--templates" ]]; then
  TPL="$HOME/.local/share/godot/export_templates/${VERSION}.stable"
  if [[ ! -f "$TPL/android_source.zip" ]]; then
    mkdir -p "$TPL"
    curl -fsSL -o "$DEST/t.tpz" "$BASE/Godot_v${VERSION}-stable_export_templates.tpz"
    unzip -oq "$DEST/t.tpz" -d "$DEST/t" && mv "$DEST/t/templates/"* "$TPL/" && rm -rf "$DEST/t" "$DEST/t.tpz"
  fi
fi
"$ROOT/.tools/bin/godot" --version
