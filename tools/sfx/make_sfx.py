#!/usr/bin/env python3
"""Efectos de sonido y música sintetizados por código (obra propia, dominio público CC0).

Todos son suaves: ataque de al menos 10 ms, sin golpes fuertes, sin sonidos agudos
estridentes, y terminan en silencio. Se normalizan a -16 LUFS y se codifican en ogg Vorbis
96 kbps (ver tools/audio_norm.py).

Uso: python3 tools/sfx/make_sfx.py [--force]
Escribe en stories/<id>/sfx/ los efectos que usa cada cuento y la música en audio/music/.
"""
from __future__ import annotations

import argparse
import json
import sys
import tempfile
import wave
from pathlib import Path

import numpy as np
from scipy import signal

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import audio_norm  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
SR = 44100
RNG = np.random.default_rng(7)


def t(d: float) -> np.ndarray:
    return np.arange(int(d * SR)) / SR


def env(n: int, attack: float = 0.015, release: float = 0.12, decay: float | None = None) -> np.ndarray:
    e = np.ones(n)
    a = max(1, int(attack * SR))
    r = max(1, int(release * SR))
    e[:a] = np.linspace(0, 1, a) ** 2
    if decay:
        e[a:] = np.exp(-np.arange(n - a) / (decay * SR))
    e[-r:] *= np.linspace(1, 0, r) ** 2
    return e


def bell(freq: float, d: float = 0.8, decay: float = 0.25) -> np.ndarray:
    x = t(d)
    s = np.sin(2 * np.pi * freq * x) + 0.35 * np.sin(2 * np.pi * freq * 2.01 * x) + 0.12 * np.sin(2 * np.pi * freq * 3.0 * x)
    return s * env(len(x), 0.01, 0.1, decay)


def noise(d: float, lo: float, hi: float) -> np.ndarray:
    n = RNG.standard_normal(int(d * SR))
    sos = signal.butter(2, [lo, hi], btype="bandpass", fs=SR, output="sos")
    return signal.sosfilt(sos, n)


def lowpass(x: np.ndarray, f: float) -> np.ndarray:
    return signal.sosfilt(signal.butter(2, f, fs=SR, output="sos"), x)


def glide(f0: float, f1: float, d: float, kind: str = "sine") -> np.ndarray:
    f = np.geomspace(f0, f1, int(d * SR))
    ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(ph) if kind == "sine" else signal.sawtooth(ph)


def mix(*parts: tuple[float, np.ndarray]) -> np.ndarray:
    n = max(int(off * SR) + len(p) for off, p in parts)
    out = np.zeros(n)
    for off, p in parts:
        i = int(off * SR)
        out[i:i + len(p)] += p
    return out


def fin(x: np.ndarray) -> np.ndarray:
    x = x * env(len(x), 0.01, 0.05)
    x = x / (np.max(np.abs(x)) + 1e-9) * 0.5
    return x.astype(np.float32)


def bark() -> np.ndarray:
    def one():
        d = 0.16
        s = lowpass(glide(380, 230, d, "saw"), 1400) * env(int(d * SR), 0.015, 0.06)
        return s
    return mix((0, one()), (0.24, one()))


def meow() -> np.ndarray:
    d = 0.6
    x = t(d)
    f = 520 + 260 * np.sin(np.pi * x / d) + 10 * np.sin(2 * np.pi * 6 * x)
    s = np.sin(2 * np.pi * np.cumsum(f) / SR) + 0.3 * np.sin(4 * np.pi * np.cumsum(f) / SR)
    return lowpass(s, 2500) * env(len(x), 0.04, 0.15)


RECIPES = {
    "brillo": lambda: fin(mix((0, bell(1047, 0.7)), (0.09, bell(1319, 0.7)), (0.18, bell(1568, 0.8)))),
    "campanita": lambda: fin(bell(1175, 1.0, 0.3)),
    "campanitas": lambda: fin(mix((0, bell(784, 0.8)), (0.15, bell(988, 0.8)), (0.3, bell(1175, 0.9)))),
    "puerta": lambda: fin(mix((0, noise(0.45, 200, 900) * env(int(0.45 * SR), 0.08, 0.2)),
                              (0.3, np.sin(2 * np.pi * 110 * t(0.25)) * env(int(0.25 * SR), 0.02, 0.1, 0.07)))),
    "guau": lambda: fin(bark()),
    "miau": lambda: fin(meow()),
    "pio": lambda: fin(mix((0, glide(1600, 2300, 0.09) * env(int(0.09 * SR), 0.012, 0.03)),
                           (0.14, glide(1700, 2400, 0.09) * env(int(0.09 * SR), 0.012, 0.03)))),
    "olfato": lambda: fin(mix(*[(i * 0.16, noise(0.1, 1500, 5000) * env(int(0.1 * SR), 0.02, 0.05)) for i in range(3)])),
    "paso": lambda: fin(np.sin(2 * np.pi * 95 * t(0.3)) * env(int(0.3 * SR), 0.012, 0.1, 0.08)
                        + 0.2 * noise(0.3, 100, 600) * env(int(0.3 * SR), 0.012, 0.1, 0.03)),
    "hojas": lambda: fin(noise(0.6, 2000, 7000) * (0.6 + 0.4 * np.sin(2 * np.pi * 9 * t(0.6))) * env(int(0.6 * SR), 0.08, 0.2)),
    "burbuja": lambda: fin(mix((0, glide(280, 900, 0.12) * env(int(0.12 * SR), 0.01, 0.04)),
                               (0.16, glide(350, 1100, 0.1) * env(int(0.1 * SR), 0.01, 0.04)))),
    "agua": lambda: fin(lowpass(RNG.standard_normal(int(0.8 * SR)), 1200) * (0.7 + 0.3 * np.sin(2 * np.pi * 5 * t(0.8)))
                        * env(int(0.8 * SR), 0.1, 0.3)),
    "aleteo": lambda: fin(lowpass(RNG.standard_normal(int(0.6 * SR)), 900)
                          * np.clip(np.sin(2 * np.pi * 7 * t(0.6)), 0, None) * env(int(0.6 * SR), 0.04, 0.15)),
    "viento": lambda: fin(noise(1.2, 250, 1100) * np.sin(np.pi * t(1.2) / 1.2) ** 2),
    "abrazo": lambda: fin(sum(np.sin(2 * np.pi * f * t(0.8)) for f in (220, 277, 330)) * env(int(0.8 * SR), 0.15, 0.3)),
    "rugido_suave": lambda: fin(lowpass(signal.sawtooth(2 * np.pi * 85 * t(0.8)), 500)
                                * (0.75 + 0.25 * np.sin(2 * np.pi * 11 * t(0.8))) * env(int(0.8 * SR), 0.12, 0.3)),
    "pop": lambda: fin(glide(500, 900, 0.12) * env(int(0.12 * SR), 0.01, 0.05)),
}


def music_plaza() -> np.ndarray:
    """Cajita de música tranquila (pentatónica, 76 bpm), 16 compases que se repiten sin corte."""
    beat = 60 / 76
    notes = [0, 4, 7, 9, 7, 4, 2, 4, 0, 2, 4, 7, 9, 12, 9, 7] * 2
    base = 523.25
    total = len(notes) * beat
    out = np.zeros(int(total * SR))
    for i, n in enumerate(notes):
        f = base * 2 ** (n / 12)
        b = bell(f, beat * 2.2, 0.35) * 0.35
        start = int(i * beat * SR)
        end = min(len(out), start + len(b))
        out[start:end] += b[:end - start]
        tail = len(b) - (end - start)
        if tail > 0:  # lo que sobra al final vuelve al principio: loop sin costura
            out[:tail] += b[end - start:]
    pad_t = np.arange(len(out)) / SR
    for f in (261.6, 329.6, 392.0):
        out += 0.05 * np.sin(2 * np.pi * f * pad_t) * (0.5 - 0.5 * np.cos(2 * np.pi * pad_t / total))
    out = out / np.max(np.abs(out)) * 0.5
    return out.astype(np.float32)


def write_wav(path: Path, x: np.ndarray) -> None:
    pcm = (np.clip(x, -1, 1) * 32767).astype(np.int16)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


def render(name: str, x: np.ndarray, out: Path, bitrate: str = "96k") -> None:
    with tempfile.TemporaryDirectory() as tmp:
        wav = Path(tmp) / "x.wav"
        write_wav(wav, x)
        audio_norm.normalize(wav, out, bitrate)
    print(f"  ✓ {out.relative_to(ROOT)}")


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--force", action="store_true")
    args = ap.parse_args(argv)
    for story in sorted((ROOT / "stories").glob("*/story.json")):
        data = json.loads(story.read_text(encoding="utf-8"))
        names = {Path(t["sfx"]).stem for p in data["pages"].values() for t in p["tappables"]}
        for n in sorted(names):
            out = story.parent / "sfx" / f"{n}.ogg"
            if out.exists() and not args.force:
                continue
            render(n, RECIPES[n](), out)
    music = ROOT / "audio" / "music" / "plaza.ogg"
    if not music.exists() or args.force:
        render("plaza", music_plaza(), music)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
