"""Adds the two permissions the app needs to android/app/src/main/AndroidManifest.xml.

Run from the flutter_app folder, AFTER `flutter create . --platforms=android`:
    python tools/add_android_permissions.py

Safe to run more than once.
"""
import pathlib
import sys

path = pathlib.Path("android/app/src/main/AndroidManifest.xml")
if not path.exists():
    sys.exit("AndroidManifest.xml not found. Run `flutter create . --platforms=android` first.")

text = path.read_text(encoding="utf-8")
wanted = [
    "android.permission.INTERNET",
    "android.permission.RECORD_AUDIO",
]
missing = [p for p in wanted if p not in text]
if not missing:
    print("Permissions already present. Nothing to do.")
    sys.exit(0)

block = "".join(f"    <uses-permission android:name=\"{p}\"/>\n" for p in missing)
idx = text.find("<application")
if idx == -1:
    sys.exit("Could not find <application> in the manifest.")
text = text[:idx] + block.lstrip() + "    " + text[idx:]
path.write_text(text, encoding="utf-8")
print("Added:", ", ".join(missing))
print("If the build later complains about minSdk, set minSdk = 23 in android/app/build.gradle(.kts).")
