"""Conteo de sílabas en español y tiempos estimados por palabra.

Se usa cuando el motor de voz no da tiempos por palabra (Piper, Kokoro en español):
cada palabra dura en proporción a sus sílabas, con pausas tras la puntuación.
"""
from __future__ import annotations

SEC_PER_SYLLABLE = 0.2
GAP = 0.12        # silencio entre palabras
PAUSE = 0.28      # silencio extra después de . , ; : ! ? …
LEAD = 0.15       # silencio al principio del audio
FILL = 0.97       # fracción de la duración que ocupan las palabras al ajustar

STRONG = set("aeoáéóíú")
VOWELS = set("aeiouáéíóúü")
PUNCT = set(".,;:!?…")


def count_syllables(word: str) -> int:
    """Núcleos vocálicos: cada grupo de vocales es 1 sílaba (diptongo),
    salvo dos fuertes seguidas (hiato), que suman 1 más."""
    w = "".join(c for c in word.lower() if c.isalpha())
    count = 0
    prev = ""
    for c in w:
        if c in VOWELS:
            if prev not in VOWELS:
                count += 1
            elif prev in STRONG and c in STRONG:
                count += 1
        prev = c
    return max(1, count)


def estimate_timings(words: list[str], duration: float | None = None) -> list[dict]:
    out = []
    t = LEAD
    for w in words:
        t0 = t
        t1 = t0 + count_syllables(w) * SEC_PER_SYLLABLE
        out.append({"w": w, "t0": t0, "t1": t1})
        t = t1 + GAP + (PAUSE if w and w[-1] in PUNCT else 0.0)
    if duration and out:
        k = duration * FILL / out[-1]["t1"]
        for x in out:
            x["t0"] *= k
            x["t1"] *= k
    for x in out:
        x["t0"] = round(x["t0"], 3)
        x["t1"] = round(x["t1"], 3)
    return out


def natural_duration(words: list[str]) -> float:
    t = estimate_timings(words)
    return (t[-1]["t1"] + 0.4) if t else 0.5
