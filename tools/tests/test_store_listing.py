"""Límites de la ficha de Google Play (docs/store-listing.md)."""
import re
from pathlib import Path

DOC = Path(__file__).resolve().parents[2] / "docs" / "store-listing.md"


def field(name: str) -> str:
    text = DOC.read_text(encoding="utf-8")
    m = re.search(rf"<!-- {name} -->\n(.*?)\n<!-- /{name} -->", text, re.S)
    assert m, f"falta el bloque {name}"
    return m.group(1).strip()


def test_title_max_30():
    assert 0 < len(field("titulo")) <= 30


def test_short_description_max_80():
    assert 0 < len(field("breve")) <= 80


def test_full_description_max_4000():
    assert 0 < len(field("completa")) <= 4000


def test_no_forbidden_claims():
    full = field("completa").lower()
    for word in ("gratis", "mejor app", "#1", "descargá", "oferta"):
        assert word not in full


def test_neutral_spanish_no_voseo_in_listing():
    text = " ".join(field(n) for n in ("titulo", "breve", "completa"))
    for voseo in ("elegí", "tocá", "descubrí", "querés", "podés", "tenés"):
        assert voseo not in text.lower()
