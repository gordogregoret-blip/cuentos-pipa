#!/usr/bin/env python3
"""Genera las voces de un cuento a partir de su story.json.

Para cada página y nivel escribe vo/<página>_<nivel>.ogg y su vo/<página>_<nivel>.json con los
tiempos por palabra (karaoke). También las palabras de los tocables, las opciones de las
decisiones, el título y el mensaje. Ver docs/story-schema.md.

Audio final: ogg Vorbis mono 64 kbps, normalizado a -16 LUFS (ffmpeg loudnorm).

Ejemplos:
  python3 tools/tts/tts.py --story stories/dino --engine kokoro
  python3 tools/tts/tts.py --story stories/dino --engine piper --voice ~/voices/es_MX-claude-high.onnx
  python3 tools/tts/tts.py --ui audio/ui/phrases.json --engine piper
  python3 tools/tts/tts.py --story stories/dino --engine placeholder   # sin motor, solo silencio
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path

import engines
import syllables

LEVELS = ("simple", "cuento", "aventura")
LOUDNORM = "loudnorm=I=-16:TP=-1.5:LRA=11"


@dataclass
class Job:
    out: str               # ruta relativa a la carpeta del cuento
    text: str
    timings: str | None = None  # ruta relativa del json de tiempos


def words(text: str) -> list[str]:
    return text.split()


def jobs(story: dict) -> list[Job]:
    out = [Job("vo/title.ogg", story["title"]), Job("vo/message.ogg", story["message"])]
    for pid, page in story["pages"].items():
        for lvl in LEVELS:
            out.append(Job(f"vo/{pid}_{lvl}.ogg", page["text"][lvl], f"vo/{pid}_{lvl}.json"))
        for tap in page.get("tappables", []):
            out.append(Job(f"vo/{pid}_tap_{tap['id']}.ogg", tap["word"]))
        for i, opt in enumerate(page.get("decision", {}).get("options", [])):
            out.append(Job(f"vo/{pid}_opt{i + 1}.ogg", opt["text"]))
    return out


def ui_jobs(phrases: dict[str, str]) -> list[Job]:
    return [Job(f"{key}.ogg", text) for key, text in phrases.items()]


def encode(wav: Path, ogg: Path, normalize: bool) -> float:
    ogg.parent.mkdir(parents=True, exist_ok=True)
    af = [LOUDNORM] if normalize else []
    cmd = ["ffmpeg", "-v", "error", "-y", "-i", str(wav)]
    if af:
        cmd += ["-af", ",".join(af)]
    cmd += ["-ac", "1", "-ar", "24000", "-c:a", "libvorbis", "-b:a", "64k", str(ogg)]
    subprocess.run(cmd, check=True)
    probe = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0",
                            str(ogg)], capture_output=True, text=True, check=True)
    return float(probe.stdout.strip())


def run(base: Path, todo: list[Job], engine: engines.Engine, force: bool) -> int:
    done = 0
    with tempfile.TemporaryDirectory() as tmp:
        for job in todo:
            ogg = base / job.out
            if ogg.exists() and not force:
                continue
            wav = Path(tmp) / "v.wav"
            timings = engine.synth(job.text, wav)
            duration = encode(wav, ogg, normalize=engine.name != "placeholder")
            if job.timings:
                if timings is None:
                    timings = syllables.estimate_timings(words(job.text), duration)
                (base / job.timings).write_text(json.dumps(timings, ensure_ascii=False), encoding="utf-8")
            done += 1
            print(f"  ✓ {job.out}")
    return done


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    src = ap.add_mutually_exclusive_group(required=True)
    src.add_argument("--story", help="carpeta del cuento (con story.json)")
    src.add_argument("--ui", help="json {id: frase} de voces de la interfaz; escribe <id>.ogg al lado")
    ap.add_argument("--engine", choices=["kokoro", "piper", "placeholder"], default="kokoro")
    ap.add_argument("--voice", help="voz de Kokoro (ef_dora) o ruta al .onnx de Piper")
    ap.add_argument("--speed", type=float, default=0.9, help="velocidad de habla (0.9 = un poco lenta)")
    ap.add_argument("--only", help="solo una página (id)")
    ap.add_argument("--force", action="store_true", help="regenera aunque el archivo exista")
    args = ap.parse_args(argv)

    if args.story:
        base = Path(args.story)
        todo = jobs(json.loads((base / "story.json").read_text(encoding="utf-8")))
        if args.only:
            todo = [j for j in todo if j.out.startswith(f"vo/{args.only}_")]
    else:
        ui = Path(args.ui)
        base = ui.parent
        todo = ui_jobs(json.loads(ui.read_text(encoding="utf-8")))
    engine = engines.make(args.engine, args.voice, args.speed)
    n = run(base, todo, engine, args.force)
    print(f"{n} archivo(s) generados con {args.engine} en {base}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
