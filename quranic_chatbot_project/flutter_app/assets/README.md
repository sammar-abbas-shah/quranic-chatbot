# assets/

## quran_offline.json (optional)

A bundled copy of the whole Quran (Arabic + English + Urdu) so every Surah opens
without internet on the very first launch.

Generate it once, after your backend is deployed:

```
python tools/build_offline_quran.py https://<YOUR-PROJECT>.vercel.app
```

That writes `assets/quran_offline.json` (about 10 MB). Then open `pubspec.yaml`
and remove the `#` in front of the `assets:` lines, and run `flutter pub get`.

If you skip this, the app still works - each Surah is downloaded from the backend
the first time it is opened and then kept on the phone.
