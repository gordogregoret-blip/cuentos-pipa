"""Motores de voz. Cada uno escribe un WAV y devuelve tiempos por palabra o None.

- kokoro: Kokoro-82M (Apache-2.0), voz española `ef_dora`. Necesita `pip install kokoro soundfile`
  y `espeak-ng` instalado en el sistema.
- piper: Piper (MIT) con voces es_MX (`es_MX-claude-high`, `es_MX-ald-medium`).
  Necesita `pip install piper-tts` y el modelo .onnx (+ .onnx.json).
- placeholder: silencio con la duración estimada por sílabas (para probar sin motor).
"""
from __future__ import annotations

import subprocess
import wave
from pathlib import Path

import syllables


class Engine:
    name = ""

    def synth(self, text: str, wav_path: Path) -> list[dict] | None:
        raise NotImplementedError


class PlaceholderEngine(Engine):
    name = "placeholder"

    def synth(self, text, wav_path):
        words = text.split()
        dur = syllables.natural_duration(words)
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "lavfi", "-i",
                        "anullsrc=r=24000:cl=mono", "-t", f"{dur:.3f}", str(wav_path)], check=True)
        return syllables.estimate_timings(words)


class PiperEngine(Engine):
    name = "piper"

    def __init__(self, model: str, speed: float = 1.0):
        from piper import PiperVoice, SynthesisConfig  # import tardío: solo en la PC del autor
        self.voice = PiperVoice.load(model)
        self.config = SynthesisConfig(length_scale=1.0 / speed, noise_scale=0.5, noise_w_scale=0.6)

    def synth(self, text, wav_path):
        with wave.open(str(wav_path), "wb") as wf:
            self.voice.synthesize_wav(text, wf, syn_config=self.config)
        return None


class KokoroEngine(Engine):
    name = "kokoro"

    def __init__(self, voice: str = "ef_dora", speed: float = 1.0):
        from kokoro import KPipeline  # import tardío
        self.pipe = KPipeline(lang_code="e", repo_id="hexgrad/Kokoro-82M")
        self.voice = voice
        self.speed = speed

    def synth(self, text, wav_path):
        import numpy as np
        import soundfile as sf
        chunks, timings, offset = [], [], 0.0
        for result in self.pipe(text, voice=self.voice, speed=self.speed):
            audio = result.audio.numpy() if hasattr(result.audio, "numpy") else np.asarray(result.audio)
            for tok in (result.tokens or []):
                if getattr(tok, "start_ts", None) is not None and tok.text.strip():
                    timings.append({"w": tok.text, "t0": offset + tok.start_ts, "t1": offset + tok.end_ts})
            chunks.append(audio)
            offset += len(audio) / 24000
        sf.write(str(wav_path), np.concatenate(chunks), 24000)
        words = text.split()
        # Kokoro solo da tiempos fiables en inglés: si no coinciden con las palabras, se estiman.
        if len(timings) == len(words):
            for t, w in zip(timings, words):
                t["w"] = w
            return timings
        return None


def make(name: str, voice: str | None, speed: float) -> Engine:
    if name == "placeholder":
        return PlaceholderEngine()
    if name == "piper":
        return PiperEngine(voice or str(Path.home() / "voices" / "es_MX-claude-high.onnx"), speed)
    if name == "kokoro":
        return KokoroEngine(voice or "ef_dora", speed)
    raise ValueError(name)
