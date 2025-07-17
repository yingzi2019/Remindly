# Remindly
Flutter reminder app - Cross-platform reminder application

## Features

- **Material Design UI** - Clean, modern interface following Material Design guidelines
- **Cross-platform** - Runs on both Android and iOS
- **Repeating reminders** - Set intervals in minutes, hours, days, weeks, months, and years
- **Local notifications** - Push notifications that work even when the app is closed
- **SQLite database** - Local storage for all your reminders
- **Multi-select operations** - Select and delete multiple reminders at once
- **Date/time sorting** - Reminders automatically sorted by date and time
- **Completely free and ad-free**

## Technology Stack

This app has been refactored from the original Java/Android codebase to Flutter:

- **Flutter** - Cross-platform mobile app framework
- **Dart** - Programming language
- **sqflite** - SQLite database for Flutter
- **flutter_local_notifications** - Local push notifications
- **Material Design 3** - Modern UI components

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── reminder.dart         # Reminder data model
├── services/
│   ├── database_service.dart # SQLite database operations
│   └── notification_service.dart # Local notifications
├── screens/
│   ├── main_screen.dart      # Reminder list screen
│   ├── add_reminder_screen.dart # Add new reminder
│   ├── edit_reminder_screen.dart # Edit existing reminder
│   └── licenses_screen.dart  # Licenses information
├── widgets/
│   └── reminder_item.dart    # Individual reminder list item
└── utils/
    └── date_time_utils.dart  # Date/time utility functions
```

## Getting Started

### Prerequisites

- Flutter SDK (3.0+)
- Android Studio or VS Code
- Android device/emulator or iOS device/simulator

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yingzi2019/Remindly.git
   cd Remindly
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Building

To build for Android:
```bash
flutter build apk --release
```

To build for iOS:
```bash
flutter build ios --release
```

## Migration from Java/Android

This Flutter version maintains feature parity with the original Android app while adding cross-platform support. Key improvements include:

- **Cross-platform compatibility** - Single codebase for Android and iOS
- **Modern architecture** - Clean separation of concerns with services and models
- **Enhanced notifications** - More reliable notification system
- **Better date/time handling** - Improved parsing and formatting
- **Responsive UI** - Adaptive interface that works on different screen sizes

## Screenshots

<img src="https://github.com/blanyal/Remindly/blob/master/screenshots/screenshot1.png" width="400">

<img src="https://github.com/blanyal/Remindly/blob/master/screenshots/screenshot2.png" width="400">

<img src="https://github.com/blanyal/Remindly/blob/master/screenshots/screenshot3.png" width="400">

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

    Copyright 2015 Blanyal D'Souza

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
 
