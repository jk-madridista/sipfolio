# Sipfolio — SIP & Investment Goal Tracker

Sipfolio helps you set savings and investment goals, track SIP contributions, and visualize your progress toward financial milestones — all in one clean, mobile-first experience.

## Features

- **Goal-based tracking** — Create investment goals with target amounts, timelines, and SIP schedules
- **SIP calculator** — Project future value with customizable return rates and contribution frequencies
- **Progress dashboard** — Visual breakdown of how each goal is performing
- **Smart reminders** — Notifications for upcoming SIP dates and milestone achievements
- **Multi-goal support** — Track multiple goals simultaneously (emergency fund, house down payment, retirement, etc.)

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Dart) |
| Backend | Firebase (Auth, Firestore, Cloud Functions) |
| Monetization | Google AdMob (free tier), Google Play Billing (premium) |
| Target | Android-first |

## Getting Started

### Prerequisites

- Flutter SDK 3.x+
- Android Studio or VS Code with Flutter extension
- Firebase CLI
- A Firebase project with Firestore and Auth enabled

### Run locally

```bash
git clone https://github.com/jk-madridista/sipfolio.git
cd sipfolio
flutter pub get
flutter run
```

## Project Structure

```
lib/
├── main.dart
├── app/
│   ├── app.dart              # App root widget & theme
│   └── routes.dart           # Route definitions
├── features/
│   ├── auth/                 # Login, signup, onboarding
│   ├── dashboard/            # Home screen, goal overview
│   ├── goals/                # Create/edit/view goals
│   ├── sip/                  # SIP calculator & tracking
│   └── settings/             # Preferences, premium upgrade
├── models/                   # Data models (Goal, SIP, User)
├── services/                 # Firebase, notifications, billing
├── providers/                # State management (Riverpod)
└── shared/                   # Common widgets, theme, constants
```

## Monetization

- **Free tier** — Up to 3 goals, ad-supported
- **Premium** — Unlimited goals, no ads, advanced projections, export to CSV

## Roadmap

- [x] Project scaffolding
- [ ] Auth flow (Google Sign-In + email)
- [ ] Goal CRUD with Firestore
- [ ] SIP projection calculator
- [ ] Dashboard with progress charts
- [ ] Push notifications for SIP reminders
- [ ] AdMob integration
- [ ] Premium upgrade via Google Play Billing
- [ ] Dark mode

## License

MIT
