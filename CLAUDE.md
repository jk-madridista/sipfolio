# CLAUDE.md — Sipfolio

## Project Overview
Sipfolio is a freemium SIP/investment goal tracker for Android. Built with Flutter + Firebase.

## Tech Stack
- **Framework:** Flutter 3.x (Dart)
- **State Management:** Riverpod
- **Backend:** Firebase (Auth, Firestore, Cloud Functions)
- **Monetization:** Google AdMob (free tier ads), Google Play Billing (premium)
- **Target Platform:** Android-first

## Architecture
- Feature-first folder structure under `lib/features/`
- Each feature has its own screens, widgets, providers, and repositories
- Models in `lib/models/`, services in `lib/services/`
- Riverpod for state management — prefer `AsyncNotifier` pattern

## Coding Standards
- Use `const` constructors wherever possible
- Prefer named parameters for widgets
- All Firestore operations go through repository classes in `lib/services/`
- No business logic in widgets — keep it in providers/notifiers
- Use `freezed` + `json_serializable` for data models
- Dart file names: snake_case. Class names: PascalCase

## Run Commands
- `flutter pub get` — install dependencies
- `flutter run` — run on connected device/emulator
- `flutter analyze` — lint check
- `flutter test` — run tests
- `flutterfire configure` — set up Firebase

## Key Decisions
- Free users get up to 3 goals with ads. Premium unlocks unlimited goals, no ads, CSV export.
- Google Sign-In as primary auth, email/password as fallback
- Firestore security rules must restrict users to their own documents
- SIP projections use compound interest formula with configurable return rate

## Things to Avoid
- Do not use `setState` — use Riverpod providers
- Do not hardcode strings — use a constants file or l10n
- Do not store sensitive keys in code — use environment config
