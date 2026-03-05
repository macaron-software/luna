#!/usr/bin/env python3
"""
Upload LUNA Play Store listings + screenshots via Google Play Developer API.

Usage:
    python3 scripts/upload_play_store.py --key fastlane/google-play-key.json [--dry-run]

Requirements:
    pip install google-api-python-client google-auth

To get the JSON key:
    Play Console → Setup → API access → Service accounts → Create / Grant access
    Role needed: "Release manager" or "Play store listing editor"
"""

import argparse
import json
import os
import sys
import mimetypes

PACKAGE = "app.luna"
METADATA_DIR = "fastlane/metadata/android"

# Google Play locale codes that differ from our folder names
LOCALE_MAP = {
    "ar-SA": "ar",       # Play Store uses 'ar' not 'ar-SA'
    "zh-CN": "zh-CN",
    "pt-BR": "pt-BR",
    "ko-KR": "ko-KR",
}


def gp_locale(folder_locale: str) -> str:
    return LOCALE_MAP.get(folder_locale, folder_locale)


def read_file(path: str) -> str:
    if os.path.exists(path):
        return open(path, encoding="utf-8").read().strip()
    return ""


def build_service(key_file: str):
    from google.oauth2 import service_account
    from googleapiclient.discovery import build

    creds = service_account.Credentials.from_service_account_file(
        key_file,
        scopes=["https://www.googleapis.com/auth/androidpublisher"],
    )
    return build("androidpublisher", "v3", credentials=creds, cache_discovery=False)


def upload(key_file: str, dry_run: bool):
    service = build_service(key_file)
    edits = service.edits()

    # ── Open edit ────────────────────────────────────────────────────────────
    edit = edits.insert(packageName=PACKAGE, body={}).execute()
    edit_id = edit["id"]
    print(f"Opened edit: {edit_id}")

    locales = sorted(os.listdir(METADATA_DIR))
    errors = []

    for folder in locales:
        locale_dir = os.path.join(METADATA_DIR, folder)
        if not os.path.isdir(locale_dir):
            continue

        gp_loc = gp_locale(folder)
        title       = read_file(f"{locale_dir}/title.txt")
        short_desc  = read_file(f"{locale_dir}/short_description.txt")
        full_desc   = read_file(f"{locale_dir}/full_description.txt")

        if not title:
            print(f"  [{folder}] SKIP — no title.txt")
            continue

        print(f"\n── {folder} ({gp_loc}) ──────────────────────────────")
        print(f"  Title:  {title[:50]}")
        print(f"  Short:  {short_desc[:50]}")
        print(f"  Full:   {full_desc[:60]}...")

        if not dry_run:
            try:
                edits.listings().update(
                    packageName=PACKAGE,
                    editId=edit_id,
                    language=gp_loc,
                    body={
                        "language": gp_loc,
                        "title": title,
                        "shortDescription": short_desc,
                        "fullDescription": full_desc,
                    },
                ).execute()
                print(f"  Listing ✓")
            except Exception as e:
                errors.append(f"{folder} listing: {e}")
                print(f"  Listing ERROR: {e}")

        # ── Screenshots ─────────────────────────────────────────────────────
        screens_dir = os.path.join(locale_dir, "images", "phoneScreenshots")
        if os.path.isdir(screens_dir):
            screenshots = sorted(
                f for f in os.listdir(screens_dir) if f.lower().endswith(".png")
            )
            if screenshots and not dry_run:
                # Delete existing screenshots first
                try:
                    edits.images().deleteall(
                        packageName=PACKAGE,
                        editId=edit_id,
                        language=gp_loc,
                        imageType="phoneScreenshots",
                    ).execute()
                except Exception:
                    pass  # May not exist yet

                for i, fname in enumerate(screenshots):
                    fpath = os.path.join(screens_dir, fname)
                    try:
                        from googleapiclient.http import MediaFileUpload
                        media = MediaFileUpload(fpath, mimetype="image/png")
                        edits.images().upload(
                            packageName=PACKAGE,
                            editId=edit_id,
                            language=gp_loc,
                            imageType="phoneScreenshots",
                            media_body=media,
                        ).execute()
                        print(f"  Screenshot {i+1}/{len(screenshots)} ✓ {fname}")
                    except Exception as e:
                        errors.append(f"{folder} screenshot {fname}: {e}")
                        print(f"  Screenshot ERROR {fname}: {e}")
            elif screenshots:
                print(f"  Screenshots: {len(screenshots)} found (dry-run, skipped)")

        # ── Feature graphic ─────────────────────────────────────────────────
        fg_path = os.path.join(locale_dir, "images", "featureGraphic.png")
        if os.path.exists(fg_path) and not dry_run:
            try:
                from googleapiclient.http import MediaFileUpload
                # Delete existing
                try:
                    edits.images().deleteall(
                        packageName=PACKAGE, editId=edit_id,
                        language=gp_loc, imageType="featureGraphic",
                    ).execute()
                except Exception:
                    pass
                media = MediaFileUpload(fg_path, mimetype="image/png")
                edits.images().upload(
                    packageName=PACKAGE, editId=edit_id,
                    language=gp_loc, imageType="featureGraphic",
                    media_body=media,
                ).execute()
                print(f"  Feature graphic ✓")
            except Exception as e:
                errors.append(f"{folder} featureGraphic: {e}")
                print(f"  Feature graphic ERROR: {e}")
        elif os.path.exists(fg_path):
            print(f"  Feature graphic: found (dry-run, skipped)")

    # ── Commit or abort ──────────────────────────────────────────────────────
    if dry_run:
        print(f"\n[DRY RUN] Would commit edit {edit_id} — aborting instead")
        edits.delete(packageName=PACKAGE, editId=edit_id).execute()
        print("Edit deleted (dry run).")
    elif errors:
        print(f"\n{len(errors)} error(s) — aborting edit:")
        for e in errors:
            print(f"  {e}")
        edits.delete(packageName=PACKAGE, editId=edit_id).execute()
        sys.exit(1)
    else:
        result = edits.commit(packageName=PACKAGE, editId=edit_id).execute()
        print(f"\n✅ Edit committed: {result}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Upload LUNA Play Store metadata + screenshots")
    parser.add_argument("--key",     default="fastlane/google-play-key.json", help="Path to service account JSON")
    parser.add_argument("--dry-run", action="store_true", help="Validate without uploading")
    args = parser.parse_args()

    if not os.path.exists(args.key):
        print(f"ERROR: Key file not found: {args.key}")
        print("""
To get the key:
  1. Play Console → Setup → API access
  2. Link to a Google Cloud project (or create one)
  3. Create service account → Download JSON
  4. In Play Console → Grant access → Role: 'Release manager'
  5. Place the JSON at: fastlane/google-play-key.json
""")
        sys.exit(1)

    upload(args.key, args.dry_run)
