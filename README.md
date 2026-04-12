# Sipfolio — SIP & Investment Goal Tracker

Sipfolio helps you set savings and investment goals, track SIP contributions, and visualize your progress toward financial milestones — all in one clean, mobile-first experience.

## Screenshots

| Login | Dashboard | Goal Detail |
|-------|-----------|-------------|
| ![Login screen](docs/screenshots/login.png) | ![Dashboard](docs/screenshots/dashboard.png) | ![Goal detail](docs/screenshots/goal_detail.png) |

| Goals list | SIP Calculator | Settings |
|------------|----------------|----------|
| ![Goals](docs/screenshots/goals.png) | ![SIP calculator](docs/screenshots/sip_calculator.png) | ![Settings](docs/screenshots/settings.png) |

| Premium upgrade | Dark mode |
|-----------------|-----------|
| ![Premium](docs/screenshots/premium_upgrade.png) | ![Dark mode](docs/screenshots/dark_mode.png) |

> Screenshots will be added after the first public build.

## Features

- **Goal-based tracking** — Create investment goals with target amounts, timelines, and SIP schedules
- **SIP calculator** — Project future value with customizable return rates and contribution frequencies
- **Progress dashboard** — Visual breakdown of how each goal is performing with animated progress indicators
- **Smart reminders** — Monthly notifications on the 28th to prepare for upcoming SIP dates
- **Freemium model** — Free tier supports up to 3 goals with ads; Premium unlocks unlimited goals, no ads, and CSV export
- **Dark mode** — System-aware with a manual toggle that persists across restarts
- **Google Sign-In & email auth** — Two sign-in options with a route-guard-based auth flow

## Built With

| Package | Version | Purpose |
|---------|---------|---------|
| [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) | ^2.5.1 | State management |
| [go_router](https://pub.dev/packages/go_router) | ^14.2.0 | Declarative navigation |
| [firebase_core](https://pub.dev/packages/firebase_core) | ^3.4.0 | Firebase SDK initialisation |
| [firebase_auth](https://pub.dev/packages/firebase_auth) | ^5.3.0 | Authentication |
| [cloud_firestore](https://pub.dev/packages/cloud_firestore) | ^5.4.0 | Real-time database |
| [firebase_messaging](https://pub.dev/packages/firebase_messaging) | ^15.1.3 | Push notifications (FCM) |
| [google_sign_in](https://pub.dev/packages/google_sign_in) | ^6.2.1 | Google OAuth |
| [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) | ^18.0.1 | Scheduled local notifications |
| [google_mobile_ads](https://pub.dev/packages/google_mobile_ads) | ^5.1.0 | AdMob banner ads |
| [fl_chart](https://pub.dev/packages/fl_chart) | ^0.69.0 | SIP growth line charts |
| [shared_preferences](https://pub.dev/packages/shared_preferences) | ^2.3.2 | Persisting dark mode & notification prefs |
| [timezone](https://pub.dev/packages/timezone) | ^0.9.4 | Timezone-aware notification scheduling |
| [flutter_timezone](https://pub.dev/packages/flutter_timezone) | ^2.0.0 | Device timezone lookup |

## Architecture

Sipfolio follows a **feature-first** folder structure. Each product feature lives in its own directory under `lib/features/` and is self-contained — it owns its screens, sub-widgets, and any feature-local logic. Cross-cutting concerns (models, services, providers, shared widgets) live at the top level.

```
lib/
├── main.dart                   # App entry-point, Firebase + AdMob init
├── app/
│   ├── app.dart                # MaterialApp.router, theme wiring
│   └── routes.dart             # GoRouter definition + auth redirect guard
├── features/
│   ├── auth/                   # Login & email sign-in screens
│   ├── dashboard/              # Home screen — greeting, summary card, goal cards
│   ├── goals/                  # Goal list, create, edit, detail screens
│   ├── sip/                    # SIP projection calculator & growth chart
│   ├── premium/                # Premium upgrade screen (Play Billing placeholder)
│   └── settings/               # Dark mode toggle, notifications, sign-out
├── models/                     # Plain-Dart immutable data classes (Goal, SipEntry, UserProfile)
├── services/                   # Firestore repositories, AuthService, NotificationService
├── providers/                  # Riverpod state layer
└── shared/                     # AppTheme, constants, shared widgets
```

### State management

All state lives in **Riverpod** providers — no `setState` outside of purely local widget state. The key providers are:

| Provider | Type | What it does |
|----------|------|--------------|
| `authNotifierProvider` | `AsyncNotifierProvider<AuthNotifier, User?>` | Wraps Firebase auth stream; exposes sign-in / sign-out actions |
| `goalNotifierProvider` | `StreamNotifierProvider<GoalNotifier, List<Goal>>` | Real-time Firestore goal stream; exposes create / update / delete |
| `goalByIdProvider` | `Provider.family<Goal?, String>` | Derives a single goal from the stream by ID |
| `userProfileProvider` | `StreamProvider<UserProfile?>` | Streams the Firestore user document (includes `isPremium` flag) |
| `isPremiumProvider` | `Provider<bool>` | Derived from `userProfileProvider`; drives ad visibility and goal limits |
| `themeModeProvider` | `AsyncNotifierProvider<ThemeModeNotifier, ThemeMode>` | Reads / writes dark-mode pref from SharedPreferences |
| `notificationPreferencesProvider` | `AsyncNotifierProvider<NotificationPreferences, bool>` | Reads / writes notification-enabled pref |
| `sipEntriesProvider` | `StreamProvider.family<List<SipEntry>, String>` | Streams SIP entries for a given goal |
| `routerProvider` | `Provider<GoRouter>` | GoRouter instance; listens to auth state to trigger redirects |

The **route guard** in `routes.dart` calls `ref.read(authNotifierProvider)` on every navigation event and redirects unauthenticated users to `/login` and authenticated users away from auth routes — no dedicated splash or gate widget needed.

### Data flow

```
Firestore snapshot
      │
      ▼
GoalRepository.watchGoals()   ← StreamProvider listens
      │
      ▼
goalNotifierProvider (AsyncValue<List<Goal>>)
      │
      ├─▶ DashboardScreen   (ref.watch → rebuilds on change)
      ├─▶ GoalsScreen
      ├─▶ goalByIdProvider  (derived, Provider.family)
      │         │
      │         └─▶ GoalDetailScreen / EditGoalScreen
      └─▶ GoalNotifier.createGoal / updateGoal / deleteGoal
                │
                └─▶ GoalRepository (write)  →  Firestore
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3.x (Dart) |
| Backend | Firebase (Auth, Firestore, Cloud Functions) |
| Monetization | Google AdMob (free tier), Google Play Billing (premium) |
| Target | Android-first |

## Getting Started

### Prerequisites

- Flutter SDK 3.x+
- Android Studio or VS Code with Flutter extension
- Firebase CLI (`npm install -g firebase-tools`)
- A Firebase project with Firestore, Authentication, and Cloud Messaging enabled

### Run locally

```bash
git clone https://github.com/jk-madridista/sipfolio.git
cd sipfolio
flutterfire configure        # link to your Firebase project
flutter pub get
flutter run
```

> No code generation step required — the project uses hand-written Riverpod providers and plain-Dart models, so `flutter pub get && flutter run` is all you need.

## Monetization

- **Free tier** — Up to 3 goals, banner ad on the dashboard
- **Premium** — Unlimited goals, ad-free, CSV export *(Google Play Billing integration coming soon)*

## Roadmap

- [x] Project scaffolding
- [x] Auth flow (Google Sign-In + email/password)
- [x] Goal CRUD with Firestore real-time sync
- [x] SIP projection calculator with growth chart
- [x] Dashboard with progress cards and summary
- [x] Push notifications for SIP reminders (FCM + local)
- [x] AdMob banner ad integration (free tier)
- [x] Freemium model — goal limit enforcement, upgrade prompt
- [x] Premium upgrade screen (UI + benefits)
- [x] Dark mode with SharedPreferences persistence
- [x] Hero transitions & animated progress indicators
- [x] Brand theme (Material 3, teal/blue seed colour)
- [x] Android splash screen with Sipfolio logo
- [ ] Google Play Billing — one-time purchase unlock
- [ ] CSV export for premium users
- [ ] iOS support
- [ ] Widget (home-screen goal summary)

## License

MIT
