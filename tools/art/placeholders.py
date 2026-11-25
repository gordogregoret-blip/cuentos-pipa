#!/usr/bin/env python3
"""Arte provisorio (placeholders) para los cuentos, con la paleta y reglas de
docs/art/art-direction-brief.md:

- Personajes y cosas tocables: contorno tinta #4A2E22 de 8 px, colores saturados, mejillas.
- Fondos: sin contorno, colores claros y apagados, pocos elementos grandes.
- Los personajes provisorios llevan su nombre debajo, dibujado como trazo (con fontTools y
  Nunito), porque el importador SVG de Godot no dibuja <text>.

Uso: python3 tools/art/placeholders.py [--force]
Solo escribe los archivos que faltan (o todos con --force).
"""
from __future__ import annotations

import argparse
from pathlib import Path

from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont

ROOT = Path(__file__).resolve().parents[2]
INK = "#4A2E22"
CHEEK = "#F9B9A6"
S = f'stroke="{INK}" stroke-width="8" stroke-linejoin="round" stroke-linecap="round"'
S6 = f'stroke="{INK}" stroke-width="6" stroke-linejoin="round" stroke-linecap="round"'

_font = None


def text_path(text: str, cx: float, baseline: float, size: float) -> str:
    """Texto centrado como <path> (glifos de Nunito)."""
    global _font
    if _font is None:
        _font = TTFont(str(ROOT / "fonts" / "Nunito.ttf"))
    gs = _font.getGlyphSet(location={"wght": 800})
    cmap = _font.getBestCmap()
    upm = _font["head"].unitsPerEm
    k = size / upm
    names = [cmap.get(ord(c), ".notdef") for c in text]
    width = sum(gs[n].width for n in names) * k
    x = cx - width / 2
    pen = SVGPathPen(gs)
    for n in names:
        tp = TransformPen(pen, (k, 0, 0, -k, x, baseline))
        gs[n].draw(tp)
        x += gs[n].width * k
    return f'<path d="{pen.getCommands()}" fill="{INK}"/>'


def svg(w: int, h: int, body: str) -> str:
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">\n{body}\n</svg>\n'


def eye(x: float, y: float, s: float = 1.0) -> str:
    return (f'<ellipse cx="{x}" cy="{y}" rx="{19 * s}" ry="{25 * s}" fill="{INK}"/>'
            f'<ellipse cx="{x + 6 * s}" cy="{y - 9 * s}" rx="{6 * s}" ry="{8 * s}" fill="#FFFFFF"/>')


def cheek(x: float, y: float, s: float = 1.0) -> str:
    return f'<ellipse cx="{x}" cy="{y}" rx="{18 * s}" ry="{11 * s}" fill="{CHEEK}"/>'


def smile(x: float, y: float, w: float = 30) -> str:
    return f'<path d="M{x - w / 2} {y} Q{x} {y + w * 0.6} {x + w / 2} {y}" fill="none" {S6}/>'


def named(w: int, h: int, body: str, name: str) -> str:
    """Personaje con su nombre debajo, sobre un cartelito crema."""
    tag_w = max(160, 34 * len(name) + 60)
    tag = (f'<rect x="{w / 2 - tag_w / 2}" y="{h - 70}" width="{tag_w}" height="62" rx="31" fill="#FFF6E8" {S6}/>'
           + text_path(name, w / 2, h - 24, 44))
    return svg(w, h, body + tag)


# ------------------------------------------------------------------ personajes

def rex() -> str:
    c, d = "#8FC27A", "#6FA35C"
    b = (f'<path d="M120 520 Q40 560 30 470 Q90 470 150 440 Z" fill="{c}" {S}/>'
         f'<ellipse cx="260" cy="470" rx="150" ry="130" fill="{c}" {S}/>'
         f'<ellipse cx="270" cy="500" rx="85" ry="80" fill="#F3E3B5"/>'
         f'<rect x="170" y="540" width="60" height="90" rx="28" fill="{d}" {S}/>'
         f'<rect x="290" y="540" width="60" height="90" rx="28" fill="{d}" {S}/>'
         f'<ellipse cx="320" cy="230" rx="170" ry="140" fill="{c}" {S}/>'
         f'<path d="M370 430 q30 10 40 -10" fill="none" {S}/>'
         + eye(270, 200) + eye(390, 200) + cheek(240, 260) + cheek(420, 260)
         + f'<path d="M290 290 Q330 315 370 290" fill="none" {S6}/>'
         + f'<path d="M210 140 q20 -40 40 0 q20 -40 40 0 q20 -40 40 0" fill="none" {S6}/>')
    return named(520, 720, b, "Rex")


def tina() -> str:
    c, d = "#F2B880", "#D99A62"
    b = (f'<ellipse cx="300" cy="330" rx="200" ry="120" fill="{c}" {S}/>'
         f'<rect x="170" y="400" width="56" height="80" rx="26" fill="{d}" {S}/>'
         f'<rect x="370" y="400" width="56" height="80" rx="26" fill="{d}" {S}/>'
         f'<path d="M110 330 Q60 340 40 300" fill="none" {S}/>'
         f'<ellipse cx="470" cy="210" rx="120" ry="115" fill="#E6A3B4" {S}/>'
         f'<ellipse cx="470" cy="260" rx="95" ry="80" fill="{c}" {S}/>'
         f'<path d="M430 200 l-14 -60 l30 50 Z" fill="#FFF6E8" {S6}/>'
         f'<path d="M510 200 l14 -60 l-30 50 Z" fill="#FFF6E8" {S6}/>'
         f'<path d="M470 290 l0 -26" {S6}/>'
         + eye(440, 250, 0.8) + eye(500, 250, 0.8) + cheek(420, 290, 0.8) + cheek(520, 290, 0.8)
         + smile(470, 300, 26))
    return named(620, 560, b, "Tina")


def brachi() -> str:
    c, d = "#A8C7E8", "#86A9D0"
    b = (f'<ellipse cx="200" cy="560" rx="170" ry="110" fill="{c}" {S}/>'
         f'<rect x="90" y="620" width="56" height="90" rx="26" fill="{d}" {S}/>'
         f'<rect x="250" y="620" width="56" height="90" rx="26" fill="{d}" {S}/>'
         f'<path d="M300 500 Q380 300 360 120" fill="none" stroke="{INK}" stroke-width="86" stroke-linecap="round"/>'
         f'<path d="M300 500 Q380 300 360 120" fill="none" stroke="{c}" stroke-width="70" stroke-linecap="round"/>'
         f'<ellipse cx="380" cy="100" rx="80" ry="58" fill="{c}" {S}/>'
         + eye(395, 88, 0.7) + cheek(420, 118, 0.7) + smile(410, 120, 22))
    return named(500, 790, b, "Brachi")


def ptera(baby: bool) -> str:
    c, w = ("#F7B3C2", "#F28FA3") if baby else ("#C9A3E0", "#A884C9")
    sc = 0.7 if baby else 1.0
    W, H = (420, 400) if baby else (640, 520)
    cx = W / 2
    b = (f'<path d="M{cx} {200 * sc + 40} Q{cx - 260 * sc} {120 * sc} {cx - 300 * sc} {260 * sc + 40} '
         f'Q{cx - 150 * sc} {230 * sc + 40} {cx} {300 * sc + 40} Z" fill="{w}" {S}/>'
         f'<path d="M{cx} {200 * sc + 40} Q{cx + 260 * sc} {120 * sc} {cx + 300 * sc} {260 * sc + 40} '
         f'Q{cx + 150 * sc} {230 * sc + 40} {cx} {300 * sc + 40} Z" fill="{w}" {S}/>'
         f'<ellipse cx="{cx}" cy="{270 * sc + 40}" rx="{70 * sc}" ry="{90 * sc}" fill="{c}" {S}/>'
         f'<ellipse cx="{cx}" cy="{150 * sc + 40}" rx="{80 * sc}" ry="{70 * sc}" fill="{c}" {S}/>'
         f'<path d="M{cx + 50 * sc} {150 * sc + 40} L{cx + 140 * sc} {170 * sc + 40} L{cx + 50 * sc} {185 * sc + 40} Z" fill="#F59B2F" {S6}/>'
         f'<path d="M{cx - 30 * sc} {90 * sc + 40} L{cx - 90 * sc} {40 * sc + 40}" {S}/>'
         + eye(cx - 25 * sc, 140 * sc + 40, sc) + eye(cx + 25 * sc, 140 * sc + 40, sc)
         + cheek(cx - 45 * sc, 175 * sc + 40, sc))
    return named(W, H, b, "Ptera bebé" if baby else "Mamá Ptera")


def pato() -> str:
    b = (f'<ellipse cx="200" cy="330" rx="140" ry="110" fill="#FFE08A" {S}/>'
         f'<path d="M120 320 Q170 280 230 330" fill="none" {S6}/>'
         f'<circle cx="230" cy="170" r="90" fill="#FFE08A" {S}/>'
         f'<path d="M300 180 Q370 185 360 215 Q330 230 290 210 Z" fill="#F59B2F" {S6}/>'
         f'<rect x="150" y="425" width="30" height="40" rx="12" fill="#F59B2F" {S6}/>'
         f'<rect x="230" y="425" width="30" height="40" rx="12" fill="#F59B2F" {S6}/>'
         + eye(220, 150, 0.8) + eye(270, 150, 0.8) + cheek(200, 195, 0.8))
    return named(420, 560, b, "Coco")


def gallo() -> str:
    b = (f'<path d="M80 250 Q40 170 90 130 Q100 200 140 230 Z" fill="#7FC28E" {S}/>'
         f'<ellipse cx="200" cy="280" rx="120" ry="100" fill="#FFF1DA" {S}/>'
         f'<circle cx="250" cy="150" r="70" fill="#FFF1DA" {S}/>'
         f'<path d="M220 90 q10 -40 25 0 q10 -40 25 0 q10 -40 25 5" fill="#E8806E" {S6}/>'
         f'<path d="M310 150 L355 165 L310 180 Z" fill="#F59B2F" {S6}/>'
         f'<ellipse cx="300" cy="200" rx="12" ry="20" fill="#E8806E" {S6}/>'
         + eye(260, 140, 0.7) + cheek(240, 175, 0.7))
    return named(420, 470, b, "Kiko")


# ------------------------------------------------------------------ objetos

def obj(w: int, h: int, body: str) -> str:
    return svg(w, h, body)


OBJECTS = {
    "huevo": lambda: obj(260, 300,
        '<ellipse cx="130" cy="165" rx="125" ry="135" fill="#FFF3B8" opacity="0.7"/>'
        f'<ellipse cx="130" cy="170" rx="90" ry="115" fill="#FFF6E8" {S}/>'
        '<ellipse cx="100" cy="130" rx="22" ry="32" fill="#FFFFFF"/>'
        '<circle cx="155" cy="200" r="14" fill="#B3E0D2"/><circle cx="110" cy="230" r="10" fill="#B3E0D2"/>'),
    "puerta_verde": lambda: obj(260, 340,
        f'<path d="M20 330 V130 A110 110 0 0 1 240 130 V330 Z" fill="#7FC28E" {S}/>'
        f'<circle cx="190" cy="220" r="12" fill="#FFD86B" {S6}/>'),
    "huellas": lambda: obj(300, 200, "".join(
        f'<g transform="translate({x} {y}) rotate({r})"><ellipse cx="0" cy="0" rx="34" ry="26" fill="#B98C63" {S6}/>'
        f'<circle cx="-24" cy="-34" r="11" fill="#B98C63" {S6}/><circle cx="0" cy="-42" r="11" fill="#B98C63" {S6}/>'
        f'<circle cx="24" cy="-34" r="11" fill="#B98C63" {S6}/></g>'
        for x, y, r in [(60, 150, -15), (150, 100, 5), (240, 140, -10)])),
    "huella_dorada": lambda: obj(160, 160,
        '<circle cx="80" cy="84" r="74" fill="#FFF3B8" opacity="0.75"/>'
        f'<ellipse cx="80" cy="100" rx="36" ry="28" fill="#FFD86B" {S6}/>'
        f'<circle cx="54" cy="62" r="12" fill="#FFD86B" {S6}/><circle cx="80" cy="52" r="12" fill="#FFD86B" {S6}/>'
        f'<circle cx="106" cy="62" r="12" fill="#FFD86B" {S6}/>'),
    "helecho": lambda: obj(260, 300,
        f'<path d="M130 290 Q120 160 150 30" fill="none" {S}/>' + "".join(
            f'<ellipse cx="{130 + s * 45}" cy="{y}" rx="48" ry="20" fill="#7FC28E" {S6} transform="rotate({s * -25} {130 + s * 45} {y})"/>'
            for y in (80, 130, 180, 230) for s in (-1, 1))),
    "burbuja": lambda: obj(180, 180,
        f'<circle cx="90" cy="90" r="76" fill="#D6F0F7" {S}/><ellipse cx="65" cy="62" rx="18" ry="12" fill="#FFFFFF"/>'),
    "pez": lambda: obj(240, 160,
        f'<path d="M180 80 L235 40 L235 120 Z" fill="#F5A04A" {S}/>'
        f'<ellipse cx="110" cy="80" rx="90" ry="58" fill="#F5A04A" {S}/>' + eye(70, 70, 0.6)),
    "cascada": lambda: obj(260, 320,
        '<rect x="50" y="10" width="160" height="290" rx="40" fill="#BFE4F2"/>'
        f'<path d="M80 30 V280 M130 20 V290 M180 30 V280" {S6} stroke="#FFFFFF"/>'
        f'<ellipse cx="130" cy="290" rx="120" ry="28" fill="#D6F0F7" {S6}/>'),
    "piedra": lambda: obj(220, 140,
        f'<path d="M20 120 Q10 60 70 40 Q130 10 180 40 Q215 70 200 120 Z" fill="#B9B0A6" {S}/>'
        '<ellipse cx="90" cy="60" rx="30" ry="12" fill="#D2CAC1"/>'),
    "arcoiris": lambda: obj(300, 170, "".join(
        f'<path d="M{20 + i * 22} 160 A{130 - i * 22} {130 - i * 22} 0 0 1 {280 - i * 22} 160" fill="none" stroke="{c}" stroke-width="22" stroke-linecap="round"/>'
        for i, c in enumerate(["#E8806E", "#FFD86B", "#7FC28E", "#6FA8DC"]))),
    "arbol_canta": lambda: obj(260, 340,
        f'<rect x="105" y="190" width="50" height="140" rx="20" fill="#C8693B" {S}/>'
        f'<circle cx="130" cy="130" r="110" fill="#7FC28E" {S}/>'
        f'<path d="M60 120 q20 -20 40 0 q20 20 40 0 q20 -20 40 0" fill="none" {S6} stroke="#FFF6E8"/>'
        f'<path d="M80 170 q20 -15 40 0 q20 15 40 0" fill="none" {S6} stroke="#FFF6E8"/>'),
    "montana": lambda: obj(320, 240,
        f'<path d="M10 230 L160 20 L310 230 Z" fill="#B7A4CF" {S}/>'
        f'<path d="M115 85 L160 20 L205 85 Q180 100 160 85 Q140 100 115 85 Z" fill="#FFFFFF" {S6}/>'),
    "mariposa": lambda: obj(180, 160,
        f'<ellipse cx="55" cy="60" rx="48" ry="40" fill="#6FA8DC" {S6}/><ellipse cx="125" cy="60" rx="48" ry="40" fill="#6FA8DC" {S6}/>'
        f'<ellipse cx="62" cy="115" rx="34" ry="28" fill="#8FBCE6" {S6}/><ellipse cx="118" cy="115" rx="34" ry="28" fill="#8FBCE6" {S6}/>'
        f'<rect x="80" y="40" width="20" height="100" rx="10" fill="{INK}"/>'),
    "nido": lambda: obj(300, 170,
        f'<path d="M20 60 Q150 200 280 60 Z" fill="#C99A6B" {S}/>'
        f'<path d="M40 80 Q150 150 260 80 M60 110 Q150 165 240 110" fill="none" {S6} stroke="#A67A50"/>'),
    "nube": lambda: obj(280, 160,
        f'<path d="M50 130 Q10 130 20 95 Q25 60 70 65 Q85 20 135 30 Q175 10 200 55 Q255 50 260 95 Q265 130 225 130 Z" fill="#FFFFFF" {S}/>'),
    "luna": lambda: obj(200, 200,
        f'<circle cx="100" cy="100" r="80" fill="#FFF3B8" {S}/><circle cx="75" cy="80" r="14" fill="#F2E3A0"/>'
        f'<circle cx="125" cy="125" r="10" fill="#F2E3A0"/>'),
    "granero": lambda: obj(320, 300,
        f'<path d="M30 130 L160 30 L290 130 V290 H30 Z" fill="#E8806E" {S}/>'
        f'<rect x="115" y="180" width="90" height="110" fill="#FFF6E8" {S6}/>'
        f'<path d="M115 180 L205 290 M205 180 L115 290" {S6}/>'),
    "molino": lambda: obj(300, 320,
        f'<path d="M110 310 L130 140 L170 140 L190 310 Z" fill="#FFF1DA" {S}/>'
        f'<g transform="translate(150 140)">' + "".join(
            f'<rect x="-15" y="-120" width="30" height="110" rx="10" fill="#B9B0A6" {S6} transform="rotate({a})"/>'
            for a in (0, 90, 180, 270)) + f'<circle r="16" fill="{INK}"/></g>'),
    "semilla": lambda: (ROOT / "art" / "ui" / "semilla.svg").read_text(encoding="utf-8"),
    "arbol_plaza": lambda: (ROOT / "art" / "ui" / "arbol.svg").read_text(encoding="utf-8"),
}


def option(scene: str) -> str:
    """Imagen de una tarjeta de decisión: un recuadro con una escena simple."""
    frames = {
        "rio": '<rect width="520" height="320" fill="#BFE4F2"/><path d="M0 200 Q130 170 260 200 T520 200 V320 H0 Z" fill="#8FC7E8"/>'
               f'<circle cx="150" cy="150" r="30" fill="#D6F0F7" {S6}/><circle cx="330" cy="120" r="22" fill="#D6F0F7" {S6}/>',
        "bosque": '<rect width="520" height="320" fill="#D9EEE4"/>' + "".join(
            f'<rect x="{x + 30}" y="160" width="36" height="140" rx="14" fill="#C8693B" {S6}/><circle cx="{x + 48}" cy="140" r="70" fill="#7FC28E" {S}/>'
            for x in (40, 200, 360)),
        "piedras": '<rect width="520" height="320" fill="#D9EEE4"/>' + "".join(
            f'<rect x="{60 + i * 90}" y="{250 - i * 50}" width="110" height="50" rx="20" fill="#B9B0A6" {S6}/>' for i in range(5)),
        "brachi": '<rect width="520" height="320" fill="#D9EEE4"/>'
                  f'<ellipse cx="200" cy="250" rx="120" ry="60" fill="#A8C7E8" {S}/>'
                  f'<path d="M290 230 Q360 120 350 50" fill="none" stroke="{INK}" stroke-width="60" stroke-linecap="round"/>'
                  f'<path d="M290 230 Q360 120 350 50" fill="none" stroke="#A8C7E8" stroke-width="46" stroke-linecap="round"/>'
                  + eye(360, 50, 0.6),
        "rex": '<rect width="520" height="320" fill="#F2D3AE"/>'
               f'<ellipse cx="260" cy="230" rx="120" ry="80" fill="#8FC27A" {S}/><ellipse cx="300" cy="120" rx="90" ry="70" fill="#8FC27A" {S}/>'
               + eye(280, 110, 0.7) + eye(330, 110, 0.7) + smile(305, 145, 30),
        "solos": '<rect width="520" height="320" fill="#F2D3AE"/>'
                 f'<path d="M60 300 L260 60 L460 300 Z" fill="#B7A4CF" {S}/>'
                 f'<path d="M200 300 Q240 220 300 210 Q350 200 360 140" fill="none" {S6} stroke="#FFF6E8" stroke-dasharray="18 16"/>',
    }
    return svg(520, 320, f'<clipPath id="c"><rect width="520" height="320" rx="36"/></clipPath><g clip-path="url(#c)">{frames[scene]}</g>'
               f'<rect x="4" y="4" width="512" height="312" rx="34" fill="none" {S}/>')


# ------------------------------------------------------------------ fondos (sin contorno)

def bg(sky: str, ground: str, extra: str = "", horizon: int = 700) -> str:
    return svg(1920, 1080, f'<rect width="1920" height="1080" fill="{sky}"/>{extra}'
                           f'<rect y="{horizon}" width="1920" height="{1080 - horizon}" fill="{ground}"/>')


BACKGROUNDS = {
    "bg_plaza": lambda: (ROOT / "art" / "ui" / "plaza.svg").read_text(encoding="utf-8"),
    "bg_valle": lambda: bg("#CFE9F2", "#B5DCA4",
        '<ellipse cx="400" cy="720" rx="700" ry="200" fill="#C3E3B2"/><ellipse cx="1500" cy="700" rx="700" ry="220" fill="#C3E3B2"/>'
        '<ellipse cx="1650" cy="430" rx="90" ry="200" fill="#9ECF92"/><ellipse cx="250" cy="450" rx="80" ry="180" fill="#9ECF92"/>'),
    "bg_rio": lambda: bg("#CFE9F2", "#B5DCA4",
        '<path d="M0 640 Q480 560 960 640 T1920 640 V900 H0 Z" fill="#9FD3EA"/>'
        '<circle cx="700" cy="680" r="26" fill="#D6F0F7"/><circle cx="1100" cy="650" r="18" fill="#D6F0F7"/>', 860),
    "bg_cascada": lambda: bg("#D6EBF2", "#B5DCA4",
        '<path d="M700 0 H1300 V760 H700 Z" fill="#C9C0D9"/><rect x="900" y="0" width="200" height="760" fill="#BFE4F2"/>'
        '<ellipse cx="1000" cy="760" rx="300" ry="50" fill="#D6F0F7"/>', 780),
    "bg_bosque": lambda: bg("#D9EEE4", "#B5DCA4", "".join(
        f'<rect x="{x}" y="300" width="70" height="500" fill="#D2A27A"/><circle cx="{x + 35}" cy="{260 + (x % 3) * 30}" r="190" fill="#A9D69B"/>'
        for x in (80, 520, 1340, 1760))),
    "bg_montana": lambda: bg("#D6EBF2", "#C9DDB0",
        '<path d="M200 760 L800 160 L1400 760 Z" fill="#CFC3E0"/><path d="M900 760 L1450 260 L1950 760 Z" fill="#D9CFE8"/>'),
    "bg_nido": lambda: bg("#D6EBF2", "#CFC3E0",
        '<ellipse cx="300" cy="200" rx="140" ry="44" fill="#FFFFFF" opacity="0.8"/><ellipse cx="1500" cy="160" rx="160" ry="46" fill="#FFFFFF" opacity="0.8"/>', 780),
    "bg_cielo": lambda: bg("#C6E3F2", "#B5DCA4",
        '<circle cx="1650" cy="180" r="90" fill="#FFE9A8"/><ellipse cx="500" cy="300" rx="180" ry="50" fill="#FFFFFF" opacity="0.8"/>'
        '<ellipse cx="1200" cy="420" rx="150" ry="44" fill="#FFFFFF" opacity="0.8"/>', 860),
    "bg_granja_noche": lambda: bg("#8C9BC9", "#7FA383",
        '<circle cx="300" cy="160" r="4" fill="#FFF6E8"/><circle cx="900" cy="120" r="4" fill="#FFF6E8"/><circle cx="1300" cy="220" r="4" fill="#FFF6E8"/>'
        '<ellipse cx="960" cy="760" rx="1100" ry="150" fill="#8DB08F"/>', 760),
}

CHARACTERS = {"rex": rex, "tina": tina, "brachi": brachi, "mama_ptera": lambda: ptera(False),
              "ptera_bebe": lambda: ptera(True), "coco": pato, "kiko": gallo}
OPTIONS = {f"op_{k}": (lambda k=k: option(k)) for k in ("rio", "bosque", "piedras", "brachi", "rex", "solos")}
ALL = {**CHARACTERS, **OBJECTS, **OPTIONS, **BACKGROUNDS}


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--force", action="store_true")
    args = ap.parse_args(argv)
    import json
    import validate  # tools/validate.py
    written = 0
    for story in sorted((ROOT / "stories").glob("*/story.json")):
        data = json.loads(story.read_text(encoding="utf-8"))
        for rel in validate.art_files(data):
            if not rel.startswith("art/"):
                continue
            out = story.parent / rel
            name = Path(rel).stem
            if name not in ALL:
                print(f"  ? sin generador: {rel}")
                continue
            if out.exists() and not args.force:
                continue
            out.parent.mkdir(parents=True, exist_ok=True)
            out.write_text(ALL[name](), encoding="utf-8")
            written += 1
    print(f"{written} archivo(s) de arte provisorio escritos")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
