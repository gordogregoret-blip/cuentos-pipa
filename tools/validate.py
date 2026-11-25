#!/usr/bin/env python3
"""Validador de cuentos de Pipa.

Revisa cada `stories/<id>/story.json`:
  - cumple el JSON Schema (schema/story.schema.json);
  - cada página tiene exactamente una salida (next, decision o closing);
  - no hay páginas sueltas (todas alcanzables desde `start`);
  - todos los caminos llegan a un final y después al cierre, sin ciclos;
  - cada decisión tiene 2 opciones y cada página entre 3 y 5 tocables;
  - existen todos los archivos (arte, efectos y voces por convención);
  - las marcas del final secreto las activa algún tocable.

Exporta el árbol de cada cuento en Mermaid a docs/trees/<id>.md.

Uso:
  python3 tools/validate.py stories [--trees docs/trees] [--check-trees]
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from jsonschema import Draft202012Validator

ROOT = Path(__file__).resolve().parents[1]
SCHEMA_PATH = ROOT / "schema" / "story.schema.json"
LEVELS = ("simple", "cuento", "aventura")
CAST = {"pipa", "sofi", "bubu", "fido", "tati"}
MIN_TAPS, MAX_TAPS = 3, 5


# ---------------------------------------------------------------- convenciones

def voice_files(story: dict) -> list[str]:
    """Archivos de voz que el cuento necesita, por convención de nombres."""
    out = ["vo/title.ogg", "vo/message.ogg"]
    for pid, page in story.get("pages", {}).items():
        for lvl in LEVELS:
            out += [f"vo/{pid}_{lvl}.ogg", f"vo/{pid}_{lvl}.json"]
        for tap in page.get("tappables", []):
            out.append(f"vo/{pid}_tap_{tap['id']}.ogg")
        for i, _ in enumerate(page.get("decision", {}).get("options", [])):
            out.append(f"vo/{pid}_opt{i + 1}.ogg")
    return out


def art_files(story: dict) -> list[str]:
    out: list[str] = []
    for page in story.get("pages", {}).values():
        out.append(page["background"])
        for ch in page.get("characters", []):
            if ch["id"] not in CAST:
                out.append(ch["id"])
        for tap in page.get("tappables", []):
            if not tap["art"].startswith("cast:"):
                out.append(tap["art"])
            out.append(tap["sfx"])
        for opt in page.get("decision", {}).get("options", []):
            out.append(opt["image"])
    return out


def required_files(story: dict) -> list[str]:
    seen: dict[str, None] = {}
    for f in art_files(story) + voice_files(story):
        seen.setdefault(f, None)
    return list(seen)


# ---------------------------------------------------------------- grafo

def edges(page: dict) -> list[tuple[str, str]]:
    """(destino, etiqueta) de cada salida de una página."""
    out: list[tuple[str, str]] = []
    if page.get("next"):
        out.append((page["next"], ""))
    for opt in page.get("decision", {}).get("options", []):
        out.append((opt["to"], opt["text"]))
    if page.get("secret_next"):
        out.append((page["secret_next"], "secreto"))
    return out


def _graph_errors(story: dict) -> list[str]:
    errs: list[str] = []
    pages: dict = story["pages"]
    preview = story.get("preview", False)
    start = story["start"]
    if start not in pages:
        return [f"start '{start}' no existe"]

    for pid, page in pages.items():
        exits = sum(["next" in page and page["next"] is not None, "decision" in page, page.get("closing", False)])
        open_end = preview and page.get("next", "x") is None
        if exits != 1 and not open_end:
            errs.append(f"{pid}: tiene que tener exactamente una salida (next, decision o closing)")
        if "decision" in page and len(page["decision"]["options"]) != 2:
            errs.append(f"{pid}: la decisión tiene que tener 2 opciones")
        n = len(page["tappables"])
        if not MIN_TAPS <= n <= MAX_TAPS:
            errs.append(f"{pid}: tiene {n} tocables (tienen que ser entre {MIN_TAPS} y {MAX_TAPS})")
        ids = [t["id"] for t in page["tappables"]]
        if len(ids) != len(set(ids)):
            errs.append(f"{pid}: hay tocables con el mismo id")
        for dest, _ in edges(page):
            if dest not in pages:
                errs.append(f"{pid}: apunta a '{dest}', que no existe")
    if errs:
        return errs

    # Alcanzables
    seen: set[str] = set()
    stack = [start]
    while stack:
        pid = stack.pop()
        if pid in seen:
            continue
        seen.add(pid)
        stack += [d for d, _ in edges(pages[pid])]
    for pid in pages:
        if pid not in seen:
            errs.append(f"{pid}: página suelta (inalcanzable desde '{start}')")

    # Ciclos (DFS con colores)
    color: dict[str, int] = {}

    def dfs(pid: str) -> bool:
        color[pid] = 1
        for d, _ in edges(pages[pid]):
            if color.get(d) == 1 or (color.get(d) is None and dfs(d)):
                return True
        color[pid] = 2
        return False

    if dfs(start):
        errs.append("hay un ciclo: algún camino nunca llega a un final")
        return errs

    if preview:
        return errs

    # Cada camino llega al cierre pasando por un final
    for pid in seen:
        page = pages[pid]
        for d, _ in edges(page):
            if pages[d].get("closing") and "ending" not in page:
                errs.append(f"{pid}: llega al cierre sin pasar por un final")
    if not any(p.get("closing") for p in pages.values()):
        errs.append("no hay página de cierre (closing)")
    if not any("ending" in p for p in pages.values()):
        errs.append("no hay ningún final")

    # Final secreto
    secret = story.get("secret")
    if secret:
        if secret["page"] not in pages or "ending" not in pages[secret["page"]]:
            errs.append(f"secret.page '{secret['page']}' tiene que ser una página con final")
        flags = {t.get("flag") for p in pages.values() for t in p["tappables"]}
        for f in secret["requires"]:
            if f not in flags:
                errs.append(f"la marca '{f}' del final secreto no la activa ningún tocable")
        for pid, p in pages.items():
            if "secret_next" in p and p["secret_next"] != secret["page"]:
                errs.append(f"{pid}: secret_next tiene que ir a '{secret['page']}'")
    elif any("secret_next" in p for p in pages.values()):
        errs.append("hay secret_next pero el cuento no define 'secret'")
    return errs


# ---------------------------------------------------------------- API

def _schema_validator() -> Draft202012Validator:
    return Draft202012Validator(json.loads(SCHEMA_PATH.read_text(encoding="utf-8")))


def validate_story(story_dir: Path | str) -> list[str]:
    story_dir = Path(story_dir)
    path = story_dir / "story.json"
    try:
        story = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as e:
        return [f"no se pudo leer {path}: {e}"]
    errs = []
    for e in sorted(_schema_validator().iter_errors(story), key=lambda e: list(e.path)):
        where = "/".join(str(p) for p in e.absolute_path) or "(raíz)"
        errs.append(f"esquema: {where}: {e.message}")
    if errs:
        return errs
    if story["id"] != story_dir.name:
        errs.append(f"el id '{story['id']}' no coincide con la carpeta '{story_dir.name}'")
    errs += _graph_errors(story)
    for rel in required_files(story):
        if not (story_dir / rel).is_file():
            errs.append(f"falta el archivo {rel}")
    return errs


def _node(pid: str, page: dict) -> str:
    if "ending" in page:
        return f'{pid}(["{pid}: {page["ending"]["title"]}"])'
    if page.get("closing"):
        return f'{pid}[["{pid}: cierre"]]'
    if "decision" in page:
        return f"{pid}{{{pid}}}"
    return f"{pid}[{pid}]"


def mermaid(story: dict) -> str:
    lines = ["flowchart TD"]
    for pid, page in story["pages"].items():
        lines.append(f"  {_node(pid, page)}")
    for pid, page in story["pages"].items():
        for dest, label in edges(page):
            if label == "secreto":
                lines.append(f"{pid} -.->|secreto| {dest}")
            elif label:
                lines.append(f'{pid} -->|"{label}"| {dest}')
            else:
                lines.append(f"{pid} --> {dest}")
    return "\n".join(lines) + "\n"


def tree_markdown(story: dict) -> str:
    secret = story.get("secret")
    note = ""
    if secret:
        note = f"\nFinal secreto: con las marcas {', '.join(secret['requires'])} se va a `{secret['page']}`.\n"
    return (f"# Árbol de \"{story['title']}\"\n\n"
            "Generado por `tools/validate.py`. No editar a mano.\n" + note +
            f"\n```mermaid\n{mermaid(story)}```\n")


def story_dirs(root: Path) -> list[Path]:
    return sorted(p.parent for p in root.glob("*/story.json"))


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("root", help="carpeta con los cuentos (stories)")
    ap.add_argument("--trees", help="carpeta donde escribir los árboles Mermaid")
    ap.add_argument("--check-trees", action="store_true", help="falla si los árboles guardados están desactualizados")
    args = ap.parse_args(argv)
    root = Path(args.root)
    dirs = story_dirs(root)
    if not dirs:
        print(f"no hay cuentos en {root}", file=sys.stderr)
        return 1
    failed = False
    for d in dirs:
        errs = validate_story(d)
        if errs:
            failed = True
            print(f"✗ {d.name}: {len(errs)} error(es)")
            for e in errs:
                print(f"    - {e}")
            continue
        print(f"✓ {d.name}")
        if args.trees:
            story = json.loads((d / "story.json").read_text(encoding="utf-8"))
            out = Path(args.trees) / f"{d.name}.md"
            text = tree_markdown(story)
            if args.check_trees:
                if not out.is_file() or out.read_text(encoding="utf-8") != text:
                    failed = True
                    print(f"    - el árbol {out} está desactualizado: corré validate.py --trees")
            else:
                out.parent.mkdir(parents=True, exist_ok=True)
                out.write_text(text, encoding="utf-8")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
