"""Builds assets/quran_offline.json from your deployed backend.

Usage:
    python tools/build_offline_quran.py https://<YOUR-PROJECT>.vercel.app

Needs only Python 3.8+ (standard library). The first requests can be slow
while the backend wakes up, so each call is retried a few times.
"""
import json
import sys
import time
import urllib.request

if len(sys.argv) != 2:
    sys.exit("Usage: python tools/build_offline_quran.py https://<YOUR-PROJECT>.vercel.app")

BASE = sys.argv[1].rstrip("/")
OUT = "assets/quran_offline.json"


def get(path, tries=4):
    last = None
    for attempt in range(tries):
        try:
            with urllib.request.urlopen(BASE + path, timeout=60) as resp:
                return json.loads(resp.read().decode("utf-8"))
        except Exception as e:  # network hiccup or cold start
            last = e
            time.sleep(2 * (attempt + 1))
    raise SystemExit(f"Failed to fetch {path}: {last}")


surahs = get("/surahs")
if len(surahs) != 114:
    raise SystemExit(f"Expected 114 surahs, got {len(surahs)}")

ayahs = {}
for s in surahs:
    n = s["id"]
    ayahs[str(n)] = get(f"/surahs/{n}/ayahs")
    print(f"Surah {n:3d}/114  {len(ayahs[str(n)])} verses")

total = sum(len(v) for v in ayahs.values())
if total != 6236:
    raise SystemExit(f"Expected 6236 verses, got {total}")

with open(OUT, "w", encoding="utf-8") as f:
    json.dump({"surahs": surahs, "ayahs": ayahs}, f, ensure_ascii=False)
print(f"Wrote {OUT} ({total} verses)")
