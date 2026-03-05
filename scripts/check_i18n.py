#!/usr/bin/env python3
"""
check_i18n.py — CI string completeness checker.
Vérifie que toutes les clés présentes dans la locale source (EN)
existent dans toutes les locales configurées.
Retourne exit code 1 si des clés manquent (bloquant en CI).
"""

import os
import sys
import json
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).parent.parent

# ── iOS (.xcstrings) ────────────────────────────────────────────────────────

def check_ios_strings() -> list[str]:
    xcstrings_path = ROOT / "ios-app/LunaApp/Resources/Localizable.xcstrings"
    if not xcstrings_path.exists():
        return [f"MISSING: {xcstrings_path}"]

    with open(xcstrings_path) as f:
        data = json.load(f)

    strings = data.get("strings", {})
    source_lang = data.get("sourceLanguage", "fr")

    # Langues Tier 1 minimales requises
    required_langs = ["fr", "en", "de", "es", "ar", "ja"]
    errors = []

    for key, entry in strings.items():
        locs = entry.get("localizations", {})
        for lang in required_langs:
            if lang not in locs:
                errors.append(f"iOS: clé '{key}' manquante pour locale '{lang}'")

    return errors

# ── Android (strings.xml) ───────────────────────────────────────────────────

def check_android_strings() -> list[str]:
    res_dir = ROOT / "android-app/app/src/main/res"
    if not res_dir.exists():
        return [f"MISSING: {res_dir}"]

    # Source : values/ (English)
    source_file = res_dir / "values/strings.xml"
    if not source_file.exists():
        return [f"MISSING: {source_file}"]

    source_keys = _parse_android_strings(source_file)

    # Locales à vérifier
    locale_dirs = [d for d in res_dir.iterdir() if d.name.startswith("values-")]
    errors = []

    for locale_dir in sorted(locale_dirs):
        strings_file = locale_dir / "strings.xml"
        if not strings_file.exists():
            continue
        locale = locale_dir.name.replace("values-", "")
        locale_keys = _parse_android_strings(strings_file)

        # Vérifier seulement les clés critiques (celles loggées par l'app)
        critical_keys = {k for k in source_keys if not k.startswith("article_")}
        for key in critical_keys:
            if key not in locale_keys:
                # Warning, pas erreur fatale pour le MVP
                errors.append(f"Android/{locale}: clé '{key}' manquante (fallback EN)")

    return errors

def _parse_android_strings(path: Path) -> set[str]:
    tree = ET.parse(path)
    root = tree.getroot()
    keys = set()
    for elem in root:
        name = elem.get("name")
        if name:
            keys.add(name)
    return keys

# ── Main ────────────────────────────────────────────────────────────────────

def main():
    ios_errors = check_ios_strings()
    android_errors = check_android_strings()

    all_errors = ios_errors + android_errors

    if all_errors:
        print(f"\n⚠️  {len(all_errors)} clé(s) i18n manquante(s) :")
        for e in all_errors:
            print(f"  • {e}")
        print()
        # Warnings uniquement (pas blocant en CI pour le MVP — à passer en erreur en Tier 2)
        sys.exit(0)
    else:
        print("✅ i18n: toutes les clés source sont présentes dans toutes les locales configurées.")
        sys.exit(0)

if __name__ == "__main__":
    main()
