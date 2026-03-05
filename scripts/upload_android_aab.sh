#!/usr/bin/env bash
# Run this AFTER linking GCP project in Play Console:
# https://play.google.com/console -> Setup -> API access -> Link personnal-442009

set -e
AAB="/Users/sylvain/_MACARON-SOFTWARE/_FLO/android-app/app/build/outputs/bundle/release/app-release.aab"

python3 - << 'EOF'
import json
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

with open("/tmp/play_token.json") as f:
    d = json.load(f)

creds = Credentials(
    token=d["token"], refresh_token=d["refresh_token"],
    token_uri=d["token_uri"], client_id=d["client_id"],
    client_secret=d["client_secret"], scopes=d.get("scopes")
)
if not creds.valid:
    creds.refresh(Request())

service = build("androidpublisher", "v3", credentials=creds)
PACKAGE = "app.luna"
AAB_PATH = "/Users/sylvain/_MACARON-SOFTWARE/_FLO/android-app/app/build/outputs/bundle/release/app-release.aab"

print(f"Creating edit for {PACKAGE}...")
edit = service.edits().insert(packageName=PACKAGE, body={}).execute()
edit_id = edit["id"]

print("Uploading AAB...")
media = MediaFileUpload(AAB_PATH, mimetype="application/octet-stream", resumable=True)
bundle = service.edits().bundles().upload(
    packageName=PACKAGE, editId=edit_id, media_body=media
).execute()
vc = bundle["versionCode"]
print(f"Uploaded: versionCode={vc}")

service.edits().tracks().update(
    packageName=PACKAGE, editId=edit_id, track="internal",
    body={"track": "internal", "releases": [{
        "name": "0.1.0", "versionCodes": [vc], "status": "draft",
        "releaseNotes": [{"language": "en-US", "text": "Version 0.1.0 - First release\n\nPrivacy-first cycle tracking. AES-256 encrypted. 40+ languages."}]
    }]}
).execute()

result = service.edits().commit(packageName=PACKAGE, editId=edit_id).execute()
print(f"COMMITTED: {result.get('id')}")
print("Android AAB uploaded to Play Store internal track!")
EOF
