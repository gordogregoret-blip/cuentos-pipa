#!/usr/bin/env python3
"""Fuente de "El gallo que despertaba al sol" (stories/granja/story.json).
Cuento de prueba (preview): solo P1 y P2, para probar que la plaza carga 2 cuentos.
Uso: python3 tools/content/granja.py
"""
import json
from pathlib import Path

OUT = Path(__file__).resolve().parents[2] / "stories" / "granja" / "story.json"


def T(simple, cuento, aventura):
    return {"simple": simple, "cuento": cuento, "aventura": aventura}


def tap(id, art, x, y, size, anim, sfx, word):
    return {"id": id, "art": art, "x": x, "y": y, "size": size, "anim": anim, "sfx": f"sfx/{sfx}.ogg", "word": word}


STORY = {
    "schema": 1,
    "id": "granja",
    "title": "El gallo que despertaba al sol",
    "cast": ["pipa", "coco", "tati"],
    "message": "Cada uno ayuda a su manera.",
    "start": "p1",
    "preview": True,
    "door_color": "#FFD86B",
    "pages": {
        "p1": {
            "background": "art/bg_granja_noche.svg",
            "text": T(
                "Pipa, Coco y Tati abren la puerta amarilla. Hay una granja. Es de noche. "
                "El colgante está violeta. Pipa está sorprendida.",
                "Pipa, Coco y Tati abren la puerta amarilla. Del otro lado hay una granja. Todavía es de "
                "noche y todos los animales duermen. El colgante está violeta. Pipa está sorprendida.",
                "Pipa, Coco y Tati abren la puerta amarilla. Del otro lado hay una granja con un granero "
                "rojo y un molino. Todavía es de noche. Las vacas, las ovejas y las gallinas duermen. "
                "Coco habla muy bajito para no despertar a nadie. El colgante está violeta. "
                "Pipa está sorprendida."),
            "pendant": [{"color": "violeta", "at": 0.8}],
            "characters": [{"id": "pipa", "x": 0.24, "y": 0.66, "scale": 0.42},
                           {"id": "art/coco.svg", "x": 0.38, "y": 0.66, "scale": 0.9}],
            "tappables": [
                tap("tati", "cast:tati", 0.1, 0.6, 240, "hop", "miau", "Miau. Tati"),
                tap("luna", "art/luna.svg", 0.7, 0.18, 180, "float", "campanita", "La luna"),
                tap("granero", "art/granero.svg", 0.72, 0.5, 300, "wiggle", "puerta", "El granero"),
            ],
            "next": "p2",
        },
        "p2": {
            "background": "art/bg_granja_noche.svg",
            "text": T(
                "El gallo Kiko está triste. Kiko no puede cantar. El sol no sale. "
                "El colgante está azul. Pipa está triste.",
                "En el techo está el gallo Kiko. Kiko está triste porque no le sale la voz. Si Kiko no "
                "canta, los animales no se despiertan. El colgante está azul. Pipa está triste.",
                "Arriba del techo del granero está el gallo Kiko. Todas las mañanas Kiko canta y los "
                "animales se despiertan para recibir al sol. Pero hoy Kiko abre el pico y no le sale "
                "la voz. Kiko está triste. Tati pregunta: “¿Qué te pasa, Kiko?”. El colgante está azul. "
                "Pipa está triste."),
            "pendant": [{"color": "azul", "at": 0.85}],
            "characters": [{"id": "pipa", "x": 0.24, "y": 0.66, "scale": 0.42, "state": "triste"},
                           {"id": "art/coco.svg", "x": 0.38, "y": 0.66, "scale": 0.9}],
            "tappables": [
                tap("kiko", "art/kiko.svg", 0.68, 0.3, 240, "wiggle", "pio", "El gallo Kiko"),
                tap("tati", "cast:tati", 0.1, 0.6, 240, "hop", "miau", "Tati pregunta"),
                tap("molino", "art/molino.svg", 0.86, 0.48, 260, "spin", "viento", "El molino"),
            ],
            "next": None,
        },
    },
}

if __name__ == "__main__":
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(STORY, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"escrito {OUT}")
