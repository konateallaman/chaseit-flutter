# ChaseIt Flutter App

AI-powered invoice follow-up automation — iOS, Android & Web from one codebase.

## Quick Start

### 1. Install Flutter
```bash
# Download Flutter SDK from flutter.dev/docs/get-started/install
# Add to PATH, then verify:
flutter doctor
```

### 2. Install dependencies
```bash
cd chaseit-flutter
flutter pub get
```

### 3. Add fonts
Download Syne font from fonts.google.com/specimen/Syne
Place in: `assets/fonts/`
- Syne-Regular.ttf
- Syne-Medium.ttf
- Syne-SemiBold.ttf
- Syne-Bold.ttf
- Syne-ExtraBold.ttf

### 4. Update your API URL
Open `lib/services/ai_service.dart` and update:
```dart
static const String _baseUrl = 'https://YOUR-VERCEL-APP.vercel.app';
```

### 5. Run the app
```bash
# iOS simulator (Mac only)
flutter run -d ios

# Android emulator
flutter run -d android

# Web browser
flutter run -d chrome

# Physical device
flutter devices      # list connected devices
flutter run -d <device-id>
```

## Project Structure
```
lib/
├── main.dart                    # App entry + bottom nav
├── theme/
│   └── app_theme.dart          # Colors + theme
├── models/
│   ├── invoice.dart            # Invoice data model
│   └── client.dart             # Client data model
├── services/
│   ├── database_service.dart   # SQLite (local storage)
│   ├── app_state.dart          # State management (Provider)
│   └── ai_service.dart         # Anthropic API calls
├── widgets/
│   └── common_widgets.dart     # Reusable UI components
└── screens/
    ├── dashboard_screen.dart   # Home dashboard
    ├── invoices_screen.dart    # Invoice list + filters
    ├── invoice_form_screen.dart # Create/edit invoice
    ├── chase_screen.dart       # Single + bulk chase
    ├── payment_screen.dart     # Record partial payment
    ├── clients_screen.dart     # Client management
    └── settings_screen.dart    # Settings + integrations
```

## Deploy to App Stores

### Android (Play Store)
```bash
flutter build apk --release
# or
flutter build appbundle --release
```
Upload `build/app/outputs/flutter-apk/app-release.apk` to Play Console.

### iOS (App Store) — Mac required
```bash
flutter build ios --release
```
Open `ios/Runner.xcworkspace` in Xcode → Archive → Distribute.

### Web (Vercel)
```bash
flutter build web
```
Upload `build/web` folder to Vercel.
