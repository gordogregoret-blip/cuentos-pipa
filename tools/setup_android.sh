#!/usr/bin/env bash
# Instala el Android SDK que necesita el export Gradle de Godot 4.7 y lo configura en el editor.
# Uso: tools/setup_android.sh            (instala en ~/android-sdk)
#      ANDROID_HOME=/otra/ruta tools/setup_android.sh
# Requiere Java 17 o más nuevo (keytool incluido).
set -euo pipefail
ANDROID_HOME="${ANDROID_HOME:-$HOME/android-sdk}"
CMDLINE_ZIP="commandlinetools-linux-13114758_latest.zip"
PLATFORM="platforms;android-36"
BUILD_TOOLS="build-tools;36.1.0"
NDK="ndk;29.0.14206865"

mkdir -p "$ANDROID_HOME/cmdline-tools"
if [[ ! -x "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]]; then
  curl -fsSL -o /tmp/cmdline.zip "https://dl.google.com/android/repository/$CMDLINE_ZIP"
  unzip -oq /tmp/cmdline.zip -d /tmp/cmdline && rm /tmp/cmdline.zip
  rm -rf "$ANDROID_HOME/cmdline-tools/latest"
  mv /tmp/cmdline/cmdline-tools "$ANDROID_HOME/cmdline-tools/latest"
fi
SDKM="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
yes | "$SDKM" --sdk_root="$ANDROID_HOME" --licenses >/dev/null || true
"$SDKM" --sdk_root="$ANDROID_HOME" "platform-tools" "$PLATFORM" "$BUILD_TOOLS" "$NDK" "cmake;3.10.2.4988404" >/dev/null

# Ruta del SDK y de Java para el editor de Godot (editor_settings-4.7.tres).
JAVA_SDK="${JAVA_HOME:-$(dirname "$(dirname "$(readlink -f "$(command -v javac || command -v java)")")")}"
CFG_DIR="$HOME/.config/godot"
CFG="$CFG_DIR/editor_settings-4.7.tres"
mkdir -p "$CFG_DIR"
if [[ ! -f "$CFG" ]]; then
  printf '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n' > "$CFG"
fi
sed -i '/export\/android\/android_sdk_path/d; /export\/android\/java_sdk_path/d' "$CFG"
printf 'export/android/android_sdk_path = "%s"\nexport/android/java_sdk_path = "%s"\n' "$ANDROID_HOME" "$JAVA_SDK" >> "$CFG"
echo "Android SDK listo en $ANDROID_HOME (Java: $JAVA_SDK)"
