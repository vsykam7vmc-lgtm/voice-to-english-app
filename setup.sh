#!/usr/bin/env bash
# Run this once from the project root before opening the project in Android Studio.
# It fetches the whisper.cpp C/C++ sources that the :lib module compiles against.
set -e
cd "$(dirname "$0")"

if [ -d "whisper.cpp" ]; then
  echo "whisper.cpp/ already exists, skipping clone."
else
  echo "Cloning whisper.cpp..."
  git clone --depth 1 https://github.com/ggml-org/whisper.cpp.git
fi

echo
echo "Done. Next steps:"
echo "  1. Download a ggml model (see README.md) onto your computer."
echo "  2. Open this folder in Android Studio and let it sync Gradle."
echo "  3. Run the app on a device, then use 'Import model file' to copy"
echo "     the .bin model onto the phone from within the app."
