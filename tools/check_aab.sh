#!/usr/bin/env bash
# Revisa un .aab antes de subirlo a Play Console:
#   - no pide NINGÚN permiso (uses-permission)
#   - targetSdk 36 y minSdk 24
#   - trae arm64-v8a y armeabi-v7a
#   - pesa menos de 150 MB
# Uso: tools/check_aab.sh build/android/cuentos-pipa.aab
set -euo pipefail
AAB="${1:-build/android/cuentos-pipa.aab}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BT_VER="1.18.1"
BT="$ROOT/.tools/bundletool-$BT_VER.jar"
if [[ ! -f "$BT" ]]; then
  mkdir -p "$ROOT/.tools"
  curl -fsSL -o "$BT" "https://github.com/google/bundletool/releases/download/$BT_VER/bundletool-all-$BT_VER.jar"
fi
fail=0
manifest="$(java -jar "$BT" dump manifest --bundle="$AAB" 2>/dev/null)"
perms="$(grep -o 'uses-permission[^>]*' <<<"$manifest" || true)"
if [[ -n "$perms" ]]; then echo "✗ el manifest pide permisos:"; echo "$perms"; fail=1; else echo "✓ sin permisos"; fi
tsdk="$(grep -o 'android:targetSdkVersion="[0-9]*"' <<<"$manifest" | grep -o '[0-9]*')"
msdk="$(grep -o 'android:minSdkVersion="[0-9]*"' <<<"$manifest" | grep -o '[0-9]*')"
[[ "$tsdk" == "36" ]] && echo "✓ targetSdk 36" || { echo "✗ targetSdk = $tsdk (tiene que ser 36)"; fail=1; }
[[ "$msdk" == "24" ]] && echo "✓ minSdk 24" || { echo "✗ minSdk = $msdk (tiene que ser 24)"; fail=1; }
listing="$(unzip -l "$AAB")"
for abi in arm64-v8a armeabi-v7a; do
  if grep -q "base/lib/$abi/libgodot_android.so" <<<"$listing"; then echo "✓ $abi"; else echo "✗ falta $abi"; fail=1; fi
done
bytes="$(stat -c %s "$AAB")"
mb=$((bytes / 1024 / 1024))
(( bytes < 150 * 1024 * 1024 )) && echo "✓ tamaño ${mb} MB (< 150 MB)" || { echo "✗ tamaño ${mb} MB (>= 150 MB): usar Play Asset Delivery"; fail=1; }
if jarsigner -verify "$AAB" >/dev/null 2>&1; then echo "✓ firmado"; else echo "✗ el .aab no está firmado"; fail=1; fi
exit $fail
