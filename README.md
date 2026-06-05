# HERBB

HERBB is a Flutter mobile app focused on herbal traceability and user-friendly workflows for collection, verification, and consumer transparency. The project demonstrates practical mobile engineering with clean UI patterns, offline-aware behavior, and modular Dart architecture.

## Project Overview

This app helps track herb-related lifecycle information from source to end-user experience, with role-specific flows for contributors and consumers.

## Tech Stack

- Dart
- Flutter
- Provider (state management)
- Hive (local storage)
- Geolocator and Google Maps integrations

## Core Features

- Role-based app experience for different user journeys
- QR scan and traceability-friendly consumer workflows
- Location-aware event capture
- Offline-first local persistence and sync-ready approach
- Multilingual support and polished modern UI

## How To Run

### Prerequisites

- Flutter SDK (3.x recommended)
- Dart SDK (bundled with Flutter)
- Android Studio or VS Code with Flutter extension
- Android Emulator, iOS Simulator, or physical device

### Setup

1. Clone repository:
   ```bash
   git clone https://github.com/Itsuniquemee/HERBB.git
   cd HERBB
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Optional code generation (if needed by your setup):
   ```bash
   flutter pub run build_runner build
   ```

4. Run the app:
   ```bash
   flutter run
   ```

## Repository Structure

```text
lib/
  core/
  features/
  main.dart
```

## License

This project is available under the MIT License.
