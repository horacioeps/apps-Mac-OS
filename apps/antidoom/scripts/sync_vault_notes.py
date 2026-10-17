#!/usr/bin/env python3
"""Extrae trozos relevantes del vault Obsidian → seed_notes.json para AntiDoom."""

from __future__ import annotations

import json
import re
from datetime import datetime
from pathlib import Path

VAULT = Path.home() / "Library/Obsidian/Horacio"
OUT = Path(__file__).resolve().parents[1] / "AntiDoom/Resources/seed_notes.json"
DAILY = VAULT / "Daily_Notes"
MAX_NOTES = 4
SNIPPET_CHARS = 380


def clean_block(text: str) -> str:
    text = re.sub(r"!\[\[.*?\]\]", " ", text)
    text = re.sub(r"\[\[([^\]|]+)(?:\|[^\]]+)?\]\]", r"\1", text)
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    text = re.sub(r"`[^`]+`", " ", text)
    text = re.sub(r"https?://\S+", " ", text)
    text = re.sub(r"^#{1,6}\s*", "", text, flags=re.M)
    text = re.sub(r"^[-*]\s+\[[ xX]\]\s*", "- ", text, flags=re.M)
    text = re.sub(r"[⏫➕🛫📅⏳✅▶]+", " ", text)
    text = re.sub(r"#\w+", " ", text)
    text = re.sub(r"\s+", " ", text).strip(" -")
    return text


def score_block(text: str) -> float:
    if len(text) < 50:
        return -1.0
    # Ruido: listas de paths / wikilinks densos
    if text.count("/") >= 3 and " " not in text[:40]:
        return -1.0
    if text.lower().count("zotero/") >= 2:
        return -1.0
    score = min(len(text), 400) / 100.0
    keys = (
        "app",
        "iphone",
        "podcast",
        "prioridad",
        "hacer",
        "repo",
        "newsletter",
        "cursor",
        "vault",
        "doom",
    )
    low = text.lower()
    score += sum(1.2 for k in keys if k in low)
    if "?" in text:
        score += 0.4
    return score


def make_title(snippet: str, stem: str) -> str:
    first = re.split(r"[.!?]\s+", snippet, maxsplit=1)[0].strip()
    if len(first) > 64:
        first = first[:64].rsplit(" ", 1)[0].rstrip(" ,;:-") + "…"
    if 12 <= len(first) <= 68:
        return first
    return f"Nota {stem}"


def snippets_from_note(path: Path) -> list[dict]:
    raw = path.read_text(encoding="utf-8", errors="ignore")
    chunks = re.split(r"\n\s*\n", raw)
    scored: list[tuple[float, str]] = []
    for chunk in chunks:
        cleaned = clean_block(chunk)
        s = score_block(cleaned)
        if s > 0:
            scored.append((s, cleaned))
    scored.sort(key=lambda x: x[0], reverse=True)

    out: list[dict] = []
    date = path.stem if re.fullmatch(r"\d{4}-\d{2}-\d{2}", path.stem) else None
    for _, text in scored[:2]:
        if len(text) <= SNIPPET_CHARS:
            snippet = text
        else:
            snippet = text[: SNIPPET_CHARS - 1].rsplit(" ", 1)[0] + "…"
        out.append(
            {
                "title": make_title(snippet, path.stem),
                "summary": snippet,
                "path": f"Daily_Notes/{path.name}",
                "publishedAt": date or datetime.now().strftime("%Y-%m-%d"),
            }
        )
    return out


def main() -> None:
    if not DAILY.is_dir():
        raise SystemExit(f"No encuentro Daily_Notes en {DAILY}")

    notes = sorted(DAILY.glob("*.md"), key=lambda p: p.stat().st_mtime, reverse=True)
    items: list[dict] = []
    for note in notes[:10]:
        items.extend(snippets_from_note(note))
        if len(items) >= MAX_NOTES:
            break

    items = items[:MAX_NOTES]
    OUT.write_text(json.dumps(items, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {len(items)} notes → {OUT}")


if __name__ == "__main__":
    main()
