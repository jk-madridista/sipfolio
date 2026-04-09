# Sipfolio — Setup Checklist

Run these steps on your Ubuntu 24.04 machine to go from zero to a running app.

## 1. Create GitHub repo
```bash
# Go to github.com → New Repository → name: "sipfolio", public, no template
# Then locally:
mkdir sipfolio && cd sipfolio
git init
# Copy these starter files (README.md, CLAUDE.md, .gitignore) into the folder
git add .
git commit -m "chore: initial project setup with README and CLAUDE.md"
git remote add origin https://github.com/jk-madridista/sipfolio.git
git push -u origin main
```

## 2. Scaffold Flutter project
```bash
# From INSIDE the sipfolio directory (already has .git):
flutter create . --org com.sipfolio --project-name sipfolio --platforms android
flutter pub get
```

## 3. Add core dependencies
```bash
flutter pub add firebase_core firebase_auth cloud_firestore
flutter pub add flutter_riverpod riverpod_annotation
flutter pub add freezed_annotation json_annotation google_sign_in
flutter pub add --dev freezed build_runner json_serializable riverpod_generator
```

## 4. Wire Firebase
```bash
# Make sure Firebase CLI is installed: npm install -g firebase-tools
firebase login
flutterfire configure --project=<your-firebase-project-id>
```

## 5. Start Claude Code
```bash
cd ~/sipfolio
claude
# First prompt: "Read CLAUDE.md. Set up the feature-first folder structure under lib/"
# Next: "Create the Goal data model with freezed — fields: id, title, targetAmount, currentAmount, monthlyContribution, expectedReturnRate, targetDate, createdAt"
# Next: "Build the auth flow with Google Sign-In"
```

## 6. Verify
```bash
flutter analyze   # should pass clean
flutter run        # should launch on emulator/device
```
