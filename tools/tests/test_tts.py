"""Tests de tools/tts (sílabas, tiempos estimados, trabajos por convención, motor placeholder)."""
import json
import shutil
import subprocess
from pathlib import Path

import pytest

import syllables
import tts
import validate

ROOT = Path(__file__).resolve().parents[2]
MINI = ROOT / "test" / "fixtures" / "stories" / "mini"


@pytest.mark.parametrize("word,n", [
    ("murciélago", 4), ("Pipa", 2), ("guau", 1), ("leer", 2), ("poeta", 3),
    ("huevo", 2), ("¡Guau!", 1), ("río", 2), ("colgante", 3), ("123", 1), ("", 1),
])
def test_count_syllables(word, n):
    assert syllables.count_syllables(word) == n


def test_words_split_like_godot():
    assert tts.words("Pipa  está\ncontenta.") == ["Pipa", "está", "contenta."]


def test_estimate_timings_monotonic_and_covers_duration():
    ws = tts.words("El colgante está violeta. Pipa está sorprendida.")
    t = syllables.estimate_timings(ws, duration=6.0)
    assert [x["w"] for x in t] == ws
    for a, b in zip(t, t[1:]):
        assert a["t0"] < a["t1"] <= b["t0"]
    assert t[0]["t0"] >= 0
    assert t[-1]["t1"] <= 6.0
    assert t[-1]["t1"] > 5.0


def test_estimate_without_duration_uses_syllable_rate():
    t = syllables.estimate_timings(["Pipa", "vuela"])
    assert t[-1]["t1"] == pytest.approx(syllables.LEAD + 4 * syllables.SEC_PER_SYLLABLE + syllables.GAP, abs=0.01)


def test_jobs_follow_validator_convention():
    story = json.loads((MINI / "story.json").read_text(encoding="utf-8"))
    outs = {j.out for j in tts.jobs(story)}
    expected = {f for f in validate.voice_files(story) if f.endswith(".ogg")}
    assert outs == expected
    page_job = next(j for j in tts.jobs(story) if j.out == "vo/p1_simple.ogg")
    assert page_job.text == "Pipa está en la plaza."
    assert page_job.timings == "vo/p1_simple.json"


def test_placeholder_engine_writes_ogg_and_timings(tmp_path):
    dest = tmp_path / "mini"
    shutil.copytree(MINI, dest)
    assert tts.main(["--story", str(dest), "--engine", "placeholder", "--only", "p1"]) == 0
    ogg = dest / "vo" / "p1_simple.ogg"
    assert ogg.is_file()
    probe = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "stream=codec_name,channels",
                            "-of", "csv=p=0", str(ogg)], capture_output=True, text=True).stdout.strip()
    assert probe == "vorbis,1"
    timings = json.loads((dest / "vo" / "p1_simple.json").read_text(encoding="utf-8"))
    assert [x["w"] for x in timings] == ["Pipa", "está", "en", "la", "plaza."]


def test_skips_existing_unless_force(tmp_path):
    dest = tmp_path / "mini"
    shutil.copytree(MINI, dest)
    tts.main(["--story", str(dest), "--engine", "placeholder", "--only", "p1"])
    ogg = dest / "vo" / "p1_simple.ogg"
    mtime = ogg.stat().st_mtime_ns
    tts.main(["--story", str(dest), "--engine", "placeholder", "--only", "p1"])
    assert ogg.stat().st_mtime_ns == mtime


def test_unknown_engine_fails():
    with pytest.raises(SystemExit):
        tts.main(["--story", str(MINI), "--engine", "nada"])
