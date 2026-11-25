"""Preset de exportación Android y versionado."""
import configparser
import shutil
from pathlib import Path

import bump_version

ROOT = Path(__file__).resolve().parents[2]


def preset() -> dict:
    cp = configparser.ConfigParser(interpolation=None, strict=False)
    cp.optionxform = str
    cp.read(ROOT / "export_presets.cfg", encoding="utf-8")
    return {k: v.strip('"') for k, v in cp["preset.0.options"].items()} | {"_name": cp["preset.0"]["name"].strip('"')}


def test_android_aab_with_gradle():
    p = preset()
    assert p["_name"] == "Android"
    assert p["gradle_build/use_gradle_build"] == "true"
    assert p["gradle_build/export_format"] == "1", "1 = Android App Bundle (.aab)"
    assert p["gradle_build/min_sdk"] == "24"
    assert p["gradle_build/target_sdk"] == "36"


def test_architectures():
    p = preset()
    assert p["architectures/arm64-v8a"] == "true"
    assert p["architectures/armeabi-v7a"] == "true"
    assert p["architectures/x86"] == "false"
    assert p["architectures/x86_64"] == "false"


def test_no_permission_requested():
    on = [k for k, v in preset().items() if k.startswith("permissions/") and v == "true"]
    assert on == []


def test_no_signing_secrets_in_repo():
    p = preset()
    for k in ("keystore/release", "keystore/release_user", "keystore/release_password"):
        assert p.get(k, "") == "", f"{k} va por variable de entorno, no en el repo"


def test_version_fields():
    p = preset()
    assert int(p["version/code"]) >= 1
    assert p["version/name"] == "0.1.0"


def test_bump_version(tmp_path):
    cfg = tmp_path / "export_presets.cfg"
    shutil.copy(ROOT / "export_presets.cfg", cfg)
    before = int(preset()["version/code"])
    assert bump_version.bump(cfg) == before + 1
    text = cfg.read_text(encoding="utf-8")
    assert f"version/code={before + 1}" in text
    assert 'version/name="0.1.0"' in text
    assert bump_version.bump(cfg, name="0.2.0") == before + 2
    assert 'version/name="0.2.0"' in cfg.read_text(encoding="utf-8")
