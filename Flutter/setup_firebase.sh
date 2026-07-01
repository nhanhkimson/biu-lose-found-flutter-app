#!/usr/bin/env bash
# Generates lib/firebase_options.dart and platform config files.
# Run once after: firebase login
# firebase cli flutter fire
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

export PATH="$PATH:$HOME/.pub-cache/bin"

if ! command -v firebase >/dev/null 2>&1; then
  echo "Firebase CLI not found. Using npx firebase-tools..."
  firebase() {
    npx --yes firebase-tools "$@"
  }
fi

if ! firebase projects:list >/dev/null 2>&1; then
  echo "Log in to Firebase (browser will open)..."
  firebase login
fi

echo "Installing FlutterFire CLI..."
dart pub global activate flutterfire_cli

echo "Configuring project biu-lose-and-found..."
flutterfire configure \
  --project=biu-lose-and-found \
  --platforms=android,ios,macos \
  --yes

echo "Installing Flutter packages..."
flutter pub get

if [[ "$(uname)" == "Darwin" ]]; then
  echo "Installing iOS pods..."
  (cd ios && pod install)
fi

echo ""
echo "Firebase setup complete."
echo "Enable Email/Password in Firebase Console -> Authentication -> Sign-in method"
echo "Then run: flutter run"
