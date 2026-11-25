#!/usr/bin/env python3
"""Sube version/code (entero que Play exige que crezca en cada subida) y,
opcionalmente, cambia version/name (semántico, ej. 0.2.0) en export_presets.cfg
y en project.godot (application/config/version).

Uso: python3 tools/bump_version.py [--name 0.2.0]
"""
from __future__ import annotations

import argparse
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def bump(cfg: Path, name: str | None = None) -> int:
    text = cfg.read_text(encoding="utf-8")
    code = int(re.search(r"^version/code=(\d+)$", text, re.M).group(1)) + 1
    text = re.sub(r"^version/code=\d+$", f"version/code={code}", text, flags=re.M)
    if name:
        if not re.fullmatch(r"\d+\.\d+\.\d+", name):
            raise ValueError("version/name tiene que ser semántico: MAYOR.MENOR.PARCHE")
        text = re.sub(r'^version/name="[^"]*"$', f'version/name="{name}"', text, flags=re.M)
        proj = cfg.parent / "project.godot"
        if proj.exists():
            p = proj.read_text(encoding="utf-8")
            proj.write_text(re.sub(r'^config/version="[^"]*"$', f'config/version="{name}"', p, flags=re.M), encoding="utf-8")
    cfg.write_text(text, encoding="utf-8")
    return code


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--name")
    a = ap.parse_args()
    print(bump(ROOT / "export_presets.cfg", a.name))
