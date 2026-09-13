# SIH2K26 — Mobile

The Flutter mobile application for **KalaSetu**, the SIH2K26 project.

KalaSetu is a voice-first digital cataloging platform designed to help artisans create, manage, and publish craft product listings with minimal typing. The mobile application is the primary artisan-facing interface.

## Architecture

The application is organized into three initial layers:

```text
lib/
├── api/       # Backend and external service communication
├── ui/        # Screens, widgets, themes, and UI components
├── voice/     # Voice interaction, speech, and related services
└── main.dart  # Application entry point
```

These layers will evolve as the application features are implemented.

## Development

### Requirements

* Flutter 3.47.2 or compatible stable release
* Dart 3.13.2 or compatible version
* Android SDK
* JDK 17+
* A physical Android device or emulator

### Install dependencies

From this directory:

```bash
flutter pub get
```

### Run the application

List available devices:

```bash
flutter devices
```

Run on a specific Android device:

```bash
flutter run -d <device-id>
```

For example:

```bash
flutter run -d EUXG6L9XEUTORC5X
```

### Build APK

Debug APK:

```bash
flutter build apk --debug
```

Release APK:

```bash
flutter build apk --release
```

Generated APKs are available under:

```text
build/app/outputs/flutter-apk/
```

## Project Scope

The mobile application will progressively implement the KalaSetu workflow:

```text
Artisan
   ↓
Capture Product
   ↓
AI Image Studio
   ↓
Voice Cataloging
   ↓
Intelligence & Costing
   ↓
Three-Band Pricing
   ↓
Review & Approval
   ↓
Signed QR / Distribution
   ↓
Published Listing
```

The application will use the SIH2K26 backend services for API-driven functionality and integrate voice and AI capabilities as the corresponding features are implemented.

## Status

The Flutter application is currently scaffolded with the initial project structure. Feature implementation will be added incrementally.

## Related Applications

The SIH2K26 repository contains the complete project:

* `apps/mobile` — Flutter artisan mobile application
* `apps/api` — Backend API
* `apps/web` — Web application

## Documentation

 See [DOCS](../../docs/) for project-level architecture, implementation guidelines, API contracts, and feature specifications are maintained in the root repository.

For Flutter documentation, see the official Flutter documentation.
