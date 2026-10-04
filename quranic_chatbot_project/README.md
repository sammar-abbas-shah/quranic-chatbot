# Quranic Chatbot

An Android app (Flutter) for reading, listening to, searching and asking questions about the Holy Quran, with a small FastAPI backend hosted on Vercel.

**Start with the handbook:** `Quranic_Chatbot_Handbook.pdf` (or `.docx`). It explains every tool to install, every account and API key, how to deploy the backend, and how to build the app.

## What is in this folder

| Folder / file | What it is |
|---|---|
| `flutter_app/` | The mobile app (source code split into folders under `lib/`) |
| `backend/` | The server that is deployed to Vercel (`api/index.py`, `vercel.json`, `requirements.txt`) |
| `Quranic_Chatbot_Handbook.pdf` / `.docx` | Full setup guide with annotated pictures |
| `Quranic_Chatbot_Code_Guide_Simple.pdf` / `.docx` | Short, easy guide to how the code works (start here) |
| `Quranic_Chatbot_Code_Guide.pdf` / `.docx` | Detailed code guide with diagrams |
| `docs/figures/`, `docs/code_guide_figures/` | The pictures used in the two documents |

Original hosted backend: https://github.com/sammar-abbas-shah/quran-backend

## Quick start (details in the handbook)

1. Install Git, Flutter, Android Studio, VS Code and Python (handbook section 4).
2. Create free accounts and keys: GitHub, Vercel, Groq, Google AI Studio (section 5).
3. Deploy `backend/` to Vercel and set `GROQ_API_KEY` and `GEMINI_API_KEY` as environment variables (section 8).
4. In `flutter_app/`:
   ```
   flutter create . --platforms=android --project-name quranic_chatbot
   python tools/add_android_permissions.py
   ```
5. Open `flutter_app/lib/services.dart` and set `kBackendBaseUrl` to your Vercel URL.
6. Run it:
   ```
   flutter pub get
   flutter run
   ```
7. Build an APK to share: `flutter build apk --release`

Never put API keys in any file in this folder. They belong only in Vercel environment variables.
