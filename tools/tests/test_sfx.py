"""Efectos sintetizados y normalización de audio."""
import subprocess

import numpy as np
import pytest

import audio_norm
import make_sfx


def test_every_story_sfx_has_a_recipe():
    import json
    from pathlib import Path
    import validate
    root = Path(__file__).resolve().parents[2]
    needed = set()
    for story in root.glob("stories/*/story.json"):
        data = json.loads(story.read_text(encoding="utf-8"))
        needed |= {Path(f).stem for f in validate.art_files(data) if f.startswith("sfx/")}
    assert needed <= set(make_sfx.RECIPES), needed - set(make_sfx.RECIPES)


@pytest.mark.parametrize("name", sorted(make_sfx.RECIPES))
def test_recipes_are_soft_and_short(name):
    x = make_sfx.RECIPES[name]()
    assert x.dtype == np.float32
    assert 0.08 < len(x) / make_sfx.SR <= 1.6
    attack = int(0.008 * make_sfx.SR)
    assert np.max(np.abs(x[:attack])) < 0.5, "sin ataques bruscos"
    assert np.max(np.abs(x[-attack:])) < 0.05, "termina en silencio"


def test_normalize_hits_minus_16_lufs(tmp_path):
    wav = tmp_path / "a.wav"
    make_sfx.write_wav(wav, make_sfx.RECIPES["campanita"]())
    out = tmp_path / "a.ogg"
    audio_norm.normalize(wav, out, "96k")
    lufs = audio_norm.measure_lufs(out)
    assert lufs == pytest.approx(-16.0, abs=1.0)
    probe = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "stream=codec_name", "-of", "csv=p=0", str(out)],
                           capture_output=True, text=True).stdout.strip()
    assert probe == "vorbis"


def test_music_loop_is_seamless():
    m = make_sfx.music_plaza()
    assert len(m) / make_sfx.SR >= 15
    # Sin salto entre el final y el principio (el loop no hace "clic").
    assert abs(float(m[-1]) - float(m[0])) < 0.02
