"""Normalización de audio a -16 LUFS (EBU R128) y codificación a ogg Vorbis.

Para clips cortos (menos de 3 s) `loudnorm` de un solo paso no es exacto, así que se mide la
sonoridad integrada con silencio de relleno (el silencio queda fuera por el gate absoluto) y se
aplica la ganancia exacta, con un limitador de picos a -1.5 dBTP.
"""
from __future__ import annotations

import re
import subprocess
from pathlib import Path

TARGET = -16.0
PEAK = 0.84  # ≈ -1.5 dBFS


def measure_lufs(path: Path | str) -> float:
    r = subprocess.run(["ffmpeg", "-hide_banner", "-nostats", "-i", str(path), "-af", "apad=pad_dur=3,ebur128",
                        "-f", "null", "-"], capture_output=True, text=True)
    vals = re.findall(r"I:\s+(-?[\d.]+) LUFS", r.stderr)
    return float(vals[-1]) if vals else -70.0


def normalize(src: Path | str, out: Path | str, bitrate: str = "96k", rate: int = 44100) -> float:
    """Escribe `out` (ogg Vorbis mono) a -16 LUFS. Devuelve la duración en segundos."""
    out = Path(out)
    out.parent.mkdir(parents=True, exist_ok=True)
    gain = TARGET - measure_lufs(src)
    if gain > 40:  # silencio: no se amplifica ruido
        gain = 0.0
    af = f"volume={gain:.2f}dB,alimiter=limit={PEAK}:attack=5:release=50:level=false"
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(src), "-af", af, "-ac", "1", "-ar", str(rate),
                    "-c:a", "libvorbis", "-b:a", bitrate, str(out)], check=True)
    probe = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(out)],
                           capture_output=True, text=True, check=True)
    return float(probe.stdout.strip())
