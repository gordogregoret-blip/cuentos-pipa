# Voces (TTS)

`tools/tts/tts.py` lee un `story.json` y genera todas sus voces con la convención de
`docs/story-schema.md`: relato por página y nivel (con tiempos por palabra para el karaoke),
palabras de los tocables, opciones de las decisiones, título y mensaje.

Los motores corren en la PC del autor (o en el entorno de desarrollo), **nunca dentro de la app**.

## Motores

| Motor | Licencia | Voz | Tiempos por palabra |
|---|---|---|---|
| `kokoro` (Kokoro-82M) | Apache-2.0 | `ef_dora` (español) | Estimados por sílabas* |
| `piper` | MIT | `es_MX-claude-high` (o `es_MX-ald-medium`) | Estimados por sílabas |
| `placeholder` | — | silencio | Estimados por sílabas |

\* Kokoro solo da tiempos fiables en inglés; si no coinciden con las palabras, se estiman.

Todo sale en ogg Vorbis mono 64 kbps, normalizado a -16 LUFS (`ffmpeg loudnorm`).

## Instalación

```bash
sudo apt-get install -y ffmpeg espeak-ng
pip install -r tools/tts/requirements.txt
# Voces de Piper (es_MX):
mkdir -p ~/voices && cd ~/voices
for v in claude/high/es_MX-claude-high ald/medium/es_MX-ald-medium; do
  n=$(basename $v)
  curl -LO https://huggingface.co/rhasspy/piper-voices/resolve/main/es/es_MX/$v.onnx
  curl -LO https://huggingface.co/rhasspy/piper-voices/resolve/main/es/es_MX/$v.onnx.json
done
```

## Uso

```bash
python3 tools/tts/tts.py --story stories/dino --engine kokoro
python3 tools/tts/tts.py --story stories/dino --engine piper --voice ~/voices/es_MX-claude-high.onnx
python3 tools/tts/tts.py --ui audio/ui/phrases.json --engine piper   # voces de la interfaz
python3 tools/tts/tts.py --story stories/dino --engine kokoro --only p1 --force
```

`--speed 0.9` (por defecto) habla un poco más lento que lo normal, pensado para chicos.
Sin `--force` no se pisan archivos que ya existen.
