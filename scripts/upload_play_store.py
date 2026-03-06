#!/usr/bin/env python3
"""
Upload LUNA Play Store listings + screenshots via Google Play Developer API.

Authentication options (pick one):

  1. Service account JSON key (best for CI):
     python3 scripts/upload_play_store.py --key fastlane/google-play-key.json

  2. OAuth2 access token (fastest, no setup needed):
     a. Go to https://developers.google.com/oauthplayground/
     b. In "Input your own scopes": https://www.googleapis.com/auth/androidpublisher
     c. Authorize APIs → sign in with your Google account
     d. "Exchange authorization code for tokens"
     e. Copy the access_token value (valid 1 hour)
     python3 scripts/upload_play_store.py --token YOUR_ACCESS_TOKEN

Requirements:
    pip install google-api-python-client google-auth requests
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
    "ar-SA":  "ar",        # Play Store uses 'ar' not 'ar-SA'
    "iw-IL":  "iw",        # Hebrew — Play Store uses old ISO code 'iw' not 'he'
    "el-GR":  "el-GR",
    "hi-IN":  "hi-IN",
    "bn-BD":  "bn-BD",
    "ta-IN":  "ta-IN",
    "ms-MY":  "ms-MY",
    "nb-NO":  "no-NO",     # Play Store uses 'no-NO' for Norwegian Bokmål; folder renamed to no-NO
    "no-NO":  "no-NO",     # Canonical folder name
    "zh-CN":  "zh-CN",
    "zh-TW":  "zh-TW",
    "pt-BR":  "pt-BR",
    "pt-PT":  "pt-PT",
    "ko-KR":  "ko-KR",
    "es-419": "es-419",    # Latin American Spanish
    "fr-CA":  "fr-CA",
}


def gp_locale(folder_locale: str) -> str:
    return LOCALE_MAP.get(folder_locale, folder_locale)


def read_file(path: str) -> str:
    if os.path.exists(path):
        return open(path, encoding="utf-8").read().strip()
    return ""


def build_service(key_file: str = None, access_token: str = None):
    from googleapiclient.discovery import build

    if access_token:
        # Direct OAuth2 token (from OAuth playground or gcloud auth print-access-token)
        import google.oauth2.credentials
        creds = google.oauth2.credentials.Credentials(token=access_token)
        return build("androidpublisher", "v3", credentials=creds, cache_discovery=False)
    else:
        from google.oauth2 import service_account
        creds = service_account.Credentials.from_service_account_file(
            key_file,
            scopes=["https://www.googleapis.com/auth/androidpublisher"],
        )
        return build("androidpublisher", "v3", credentials=creds, cache_discovery=False)


def upload(key_file: str = None, access_token: str = None, dry_run: bool = False,
           only_locale: str = None, only_text: bool = False):
    service = build_service(key_file=key_file, access_token=access_token)
    edits = service.edits()

    # ── Open edit ────────────────────────────────────────────────────────────
    if dry_run:
        print(f"[DRY RUN] Would open edit for {PACKAGE} and update {len(os.listdir(METADATA_DIR))} locales")
        print(f"  Locales: {', '.join(sorted(os.listdir(METADATA_DIR)))}")
        return
    edit = edits.insert(packageName=PACKAGE, body={}).execute()
    edit_id = edit["id"]
    print(f"Opened edit: {edit_id}")

    locales = sorted(os.listdir(METADATA_DIR))
    errors = []

    for folder in locales:
        locale_dir = os.path.join(METADATA_DIR, folder)
        if not os.path.isdir(locale_dir):
            continue
        if only_locale and folder != only_locale:
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
        if only_text:
            if not dry_run: print(f"  Screenshots: skipped (--text-only)")
            continue
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
    parser = argparse.ArgumentParser(
        description="Upload LUNA Play Store metadata + screenshots",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Auth options (pick one):
  --token TOKEN      OAuth2 access token from https://developers.google.com/oauthplayground/
                     Scope: https://www.googleapis.com/auth/androidpublisher
  --key FILE         Service account JSON (default: fastlane/google-play-key.json)

Examples:
  python3 scripts/upload_play_store.py --token ya29.xxx
  python3 scripts/upload_play_store.py --token ya29.xxx --locale en-US
  python3 scripts/upload_play_store.py --token ya29.xxx --text-only
  python3 scripts/upload_play_store.py --key fastlane/google-play-key.json
""")
    parser.add_argument("--key",       default="fastlane/google-play-key.json",
                        help="Path to service account JSON key file")
    parser.add_argument("--token",     default=None,
                        help="OAuth2 access token (from OAuth playground, valid 1h)")
    parser.add_argument("--dry-run",   action="store_true", help="Validate without uploading")
    parser.add_argument("--locale",    default=None, help="Upload only this locale (e.g. en-US)")
    parser.add_argument("--text-only", action="store_true",
                        help="Upload only text (title/desc), skip screenshots")
    args = parser.parse_args()

    # Validate auth
    if not args.token and not os.path.exists(args.key):
        print("ERROR: No authentication provided.\n")
        print("Option A — OAuth2 token (no setup, 1 min):")
        print("  1. Go to https://developers.google.com/oauthplayground/")
        print("  2. Paste scope: https://www.googleapis.com/auth/androidpublisher")
        print("  3. Authorize APIs → sign in → Exchange code for tokens")
        print("  4. Copy 'access_token' → run:")
        print("     python3 scripts/upload_play_store.py --token YOUR_TOKEN\n")
        print("Option B — Service account JSON (best for CI):")
        print("  Play Console → Setup → API access → Create service account → Download JSON")
        print(f"  Place at: {args.key}")
        sys.exit(1)

    # Install deps if needed
    try:
        import googleapiclient
        import google.oauth2
    except ImportError:
        os.system("pip install google-api-python-client google-auth --quiet")

    upload(
        key_file=args.key if not args.token else None,
        access_token=args.token,
        dry_run=args.dry_run,
        only_locale=args.locale,
        only_text=args.text_only,
    )
