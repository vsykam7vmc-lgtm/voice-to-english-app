# Voice to English — offline Android app

Records speech, transcribes it in the original language, and translates it
straight into English — entirely on-device, no internet connection needed
once the model is downloaded. Built around [whisper.cpp](https://github.com/ggml-org/whisper.cpp)
(OpenAI's Whisper model, ported to C/C++ for fast on-device inference).

## How it works

1. You record audio with the mic button (16kHz mono WAV).
2. The app runs Whisper **twice** over that audio:
   - Pass 1 — transcribe in the spoken language (e.g. Telugu → Telugu text).
   - Pass 2 — translate the same audio directly into English text.
3. Both results are shown, with copy/share buttons.

This two-pass approach is intentional: Whisper's `--translate` flag replaces
the transcript with the English version rather than giving you both, so we
run it twice to get the original-language transcript *and* the English
translation.

## Project layout

```
VoiceToEnglish/
├── app/      Kotlin + Jetpack Compose UI, mic recording, WAV encode/decode
├── lib/      JNI bridge to whisper.cpp (Kotlin wrapper + C glue code)
├── setup.sh  Fetches the whisper.cpp C++ sources the native build needs
└── whisper.cpp/   (created by setup.sh — not checked in)
```

`lib` does **not** bundle whisper.cpp's source — `setup.sh` clones it
alongside this project so the native (CMake/NDK) build can compile against
it. This keeps the repo small and easy to keep in sync with upstream fixes.

## Getting an actual installable .apk

I can hand you the source code, but I can't compile it myself — this chat
environment doesn't have the Android SDK/NDK toolchain, and its network
access is restricted (no route to Google's SDK servers). Two ways to get a
real `.apk`:

### Option A — no Android Studio install needed (GitHub Actions)
1. Create a free GitHub repo and push this folder to it (`git init && git add . && git commit -m "init" && git push`).
2. GitHub will pick up `.github/workflows/build-apk.yml` automatically — it
   clones whisper.cpp, installs the NDK, and builds `app-debug.apk` on
   GitHub's servers (5–10 min).
3. Go to the repo's **Actions** tab → the latest run → download the
   `voice-to-english-debug-apk` artifact, unzip it, and you have the `.apk`.
4. Copy it to your phone and tap it to install (you may need to allow
   "install from unknown sources" once).

### Option B — Android Studio
Open the project as described below, then **Build → Build Bundle(s) / APK(s)
→ Build APK(s)**, or run `./gradlew assembleDebug` from a terminal. The APK
lands at `app/build/outputs/apk/debug/app-debug.apk`.

## One-time setup

You'll need **Android Studio** (with NDK + CMake components installed via
SDK Manager → SDK Tools) and **git**.

```bash
cd VoiceToEnglish
./setup.sh
```

This clones `whisper.cpp` into `VoiceToEnglish/whisper.cpp`. Then open the
`VoiceToEnglish` folder in Android Studio and let Gradle sync — it will
prompt to install any missing NDK/CMake components if needed.

## Getting a model

Model weights are **not bundled in the app** — you import a `.bin` file at
runtime via "Import model file" on the home screen, so the app stays small
and you can swap models without rebuilding. Download one from Hugging Face:

`https://huggingface.co/ggerganov/whisper.cpp/resolve/main/<filename>`

| File | Approx. size | Notes |
|---|---|---|
| `ggml-base.bin` | ~140 MB | Fastest, weakest accuracy on Telugu/Indian languages |
| `ggml-small.bin` | ~460 MB | Good balance for most phones |
| `ggml-small-q5_1.bin` | ~190 MB | Quantized small — smaller/faster, slightly less accurate |
| `ggml-medium-q5_0.bin` | ~530 MB | Noticeably better Telugu accuracy, slower per recording |

**Important, please read:** Whisper's training data skews heavily towards
English and a handful of major world languages. Telugu (and most Indian
languages besides Hindi) are comparatively low-resource for Whisper, so:
- `tiny`/`base` will often mangle Telugu speech badly.
- `small` is usable for clear, single-speaker speech.
- `medium` gives meaningfully better results but takes longer per
  recording on a phone CPU (expect roughly 1–4 minutes of *processing* for
  a 30-second clip on a mid-range phone with no GPU acceleration, since we
  run two full passes). There's no internet round-trip, but it isn't instant.

If accuracy matters more than offline-only operation, a cloud API (e.g. the
Sarvam AI Telugu STT you've used before) will out-perform any on-device
model of a size that fits on a phone. This app trades some accuracy for
zero network dependency, per what you asked for.

Once downloaded to your computer, copy the file to your phone's Downloads
folder (USB transfer, or `adb push <file> /sdcard/Download/`), then in the
app tap **Import model file** and pick it from Downloads.

## Building & running

In Android Studio: select a device/emulator → Run. Or from the command line:

```bash
./gradlew installDebug
```

The first native build compiles whisper.cpp's C++ core via CMake/NDK, which
takes a few minutes; subsequent builds are incremental.

## Using the app

1. Grant microphone permission when prompted.
2. Import a model (first run only).
3. Pick the spoken language (defaults to Telugu) or choose "Auto-detect".
4. Tap the mic, speak, tap stop.
5. Wait for "Transcribing and translating…" — you'll get the original-
   language text and the English translation, each with copy/share buttons.

## Known limitations / things to tune later

- No live/streaming transcription — it's record-then-process, which keeps
  the implementation simple and matches whisper.cpp's batch-oriented API.
- No background/foreground service — recording stops if you leave the app.
- Long recordings (multiple minutes) will take proportionally longer to
  process and use more memory; for long-form use, consider recording in
  shorter chunks.
- Accuracy on noisy audio, overlapping speakers, or heavy code-mixing
  (Telugu mixed with English mid-sentence) will be inconsistent — this is
  a Whisper limitation, not specific to this app.
