"""Tests del validador de cuentos (tools/validate.py)."""
import json
import shutil
from pathlib import Path

import pytest

import validate

ROOT = Path(__file__).resolve().parents[2]
MINI = ROOT / "test" / "fixtures" / "stories" / "mini"


@pytest.fixture
def story_dir(tmp_path: Path) -> Path:
    """Copia del cuento mínimo con todos los archivos que el validador espera."""
    dest = tmp_path / "mini"
    shutil.copytree(MINI, dest)
    story = json.loads((dest / "story.json").read_text(encoding="utf-8"))
    for rel in validate.required_files(story):
        f = dest / rel
        if not f.exists():
            f.parent.mkdir(parents=True, exist_ok=True)
            f.write_bytes(b"x")
    return dest


def load(d: Path) -> dict:
    return json.loads((d / "story.json").read_text(encoding="utf-8"))


def save(d: Path, story: dict) -> None:
    (d / "story.json").write_text(json.dumps(story, ensure_ascii=False), encoding="utf-8")


def errors_with(story_dir: Path, mutate) -> list[str]:
    s = load(story_dir)
    mutate(s)
    save(story_dir, s)
    return validate.validate_story(story_dir)


def test_valid_story_has_no_errors(story_dir):
    assert validate.validate_story(story_dir) == []


def test_schema_violation_is_reported(story_dir):
    errs = errors_with(story_dir, lambda s: s["pages"]["p1"]["text"].pop("cuento"))
    assert any("esquema" in e and "cuento" in e for e in errs)


def test_unreachable_page(story_dir):
    def m(s):
        s["pages"]["suelta"] = dict(s["pages"]["a6"])
    errs = errors_with(story_dir, m)
    assert any("suelta" in e and "inalcanzable" in e for e in errs)


def test_cycle_never_reaches_end(story_dir):
    def m(s):
        s["pages"]["a5"]["next"] = "p2"
    errs = errors_with(story_dir, m)
    assert any("ciclo" in e for e in errs)


def test_decision_needs_exactly_two_options(story_dir):
    def m(s):
        opts = s["pages"]["p2"]["decision"]["options"]
        opts.append(dict(opts[0]))
    errs = errors_with(story_dir, m)
    assert any("p2" in e and "2 opciones" in e for e in errs)


@pytest.mark.parametrize("n", [2, 6])
def test_tappable_count_between_3_and_5(story_dir, n):
    def m(s):
        taps = s["pages"]["p1"]["tappables"]
        while len(taps) < n:
            t = dict(taps[0])
            t["id"] = f"extra{len(taps)}"
            taps.append(t)
        del taps[n:]
    errs = errors_with(story_dir, m)
    assert any("p1" in e and "tocables" in e for e in errs)


def test_missing_background_file(story_dir):
    (story_dir / "art" / "fondo.svg").unlink()
    errs = validate.validate_story(story_dir)
    assert any("art/fondo.svg" in e for e in errs)


def test_missing_voice_file_by_convention(story_dir):
    (story_dir / "vo" / "p1_aventura.ogg").unlink()
    errs = validate.validate_story(story_dir)
    assert any("vo/p1_aventura.ogg" in e for e in errs)


def test_link_to_missing_page(story_dir):
    errs = errors_with(story_dir, lambda s: s["pages"]["p1"].__setitem__("next", "nada"))
    assert any("nada" in e and "no existe" in e for e in errs)


def test_secret_flag_nobody_sets(story_dir):
    errs = errors_with(story_dir, lambda s: s["secret"]["requires"].append("huella_9"))
    assert any("huella_9" in e for e in errs)


def test_path_reaching_closing_without_ending(story_dir):
    def m(s):
        s["pages"]["a5"]["next"] = "p7"
    errs = errors_with(story_dir, m)
    assert any("a5" in e and "final" in e for e in errs)


def test_preview_allows_open_end(story_dir):
    def m(s):
        s["preview"] = True
        s.pop("secret")
        s["pages"] = {"p1": s["pages"]["p1"]}
        s["pages"]["p1"]["next"] = None
    assert errors_with(story_dir, m) == []


def test_mermaid_tree(story_dir):
    tree = validate.mermaid(load(story_dir))
    assert tree.startswith("flowchart TD")
    assert "p1 --> p2" in tree
    assert 'p2 -->|"Ir por el río"| a5' in tree
    assert "a5 -.->|secreto| s6" in tree


def test_cli_writes_trees_and_exit_code(story_dir, tmp_path):
    trees = tmp_path / "trees"
    assert validate.main([str(story_dir.parent), "--trees", str(trees)]) == 0
    assert (trees / "mini.md").read_text(encoding="utf-8").startswith("# Árbol de")
    (story_dir / "art" / "fondo.svg").unlink()
    assert validate.main([str(story_dir.parent)]) == 1


def test_check_trees_detects_stale(story_dir, tmp_path):
    trees = tmp_path / "trees"
    validate.main([str(story_dir.parent), "--trees", str(trees)])
    assert validate.main([str(story_dir.parent), "--trees", str(trees), "--check-trees"]) == 0
    (trees / "mini.md").write_text("viejo", encoding="utf-8")
    assert validate.main([str(story_dir.parent), "--trees", str(trees), "--check-trees"]) == 1
