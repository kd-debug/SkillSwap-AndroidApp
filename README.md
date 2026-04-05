## SkillSwap

SkillSwap is a Flutter-based mobile application for micro skill exchange. It allows users to register, sign in, create and manage skills, send learning requests, explore matches, and use advanced mobile features such as maps, sensors, media, analytics, QR scanning, notifications, and API integration.

## Project Overview

This project was built as part of a Mobile Application Development practical to demonstrate end-to-end app development with:

- UI design and navigation
- Authentication and user session handling
- Feature-based architecture
- API integration
- Cloud data and media support
- Device-level advanced features
- Testing, debugging, and deployment readiness

## Main Features

- Authentication
	- Email/password login and registration
	- Google Sign-In support
	- Firebase Authentication state handling

- Skill Management
	- Add offered skills
	- View and manage personal skills
	- Skill cards with level, description, and image

- Requests and Matching
	- Create and browse skill requests
	- Match-related workflow screens

- Advanced Integrations
	- Firebase Firestore and Storage
	- Push and local notifications
	- Google Maps integration
	- Sensor data integration
	- QR/Barcode scanning
	- Media picking
	- Analytics charts
	- API demo module (remote data fetching)

## Technology Stack

- Flutter (UI framework)
- Dart (language)
- Riverpod (state management)
- Firebase Core, Auth, Firestore, Storage, Messaging
- Google Sign-In
- Dio and HTTP
- Google Maps Flutter
- Mobile Scanner
- Sensors Plus
- Image Picker
- FL Chart

## Folder Structure

The app follows a feature-first structure for better maintainability:

- lib/core
	- config
	- models
	- providers
	- services
- lib/features
	- analytics
	- api_demo
	- auth
	- explore
	- home
	- map
	- matches
	- media
	- requests
	- scanner
	- sensors
	- skills
	- tasks

## Prerequisites

Before running this project, make sure the following are installed:

- Flutter SDK (stable)
- Dart SDK
- Android Studio or Visual Studio Code
- Android emulator or physical device
- Chrome (for web run)
- Firebase project configuration

## Setup and Run

1. Clone the repository.
2. Open the project in your IDE.
3. Get dependencies:

		flutter pub get

4. Ensure Firebase files are configured for your environment.
5. Run the app:

		flutter run

For Chrome:

		flutter run -d chrome

## Build for Release

Android APK:

		flutter build apk --release

Android App Bundle (AAB):

		flutter build appbundle --release

## Testing and Quality

Run static analysis:

		flutter analyze

Run tests:

		flutter test

## Demonstration Flow

Recommended demo order during viva:

1. App launch and authentication (login/register)
2. Home screen navigation overview
3. Add skill and skill listing
4. Requests and matches flow
5. Map, scanner, media, and sensors modules
6. Analytics and API demo screen
7. Notification behavior and sign-out

## Suggested Screenshot Sections for Documentation

- Environment setup verification
- Login screen
- Register screen
- Home screen
- Skill add/manage screen
- Request and match screens
- Advanced feature screens (map/scanner/media/sensors)
- Analytics/API demo screen
- Build or deployment proof

## Future Improvements

- Role-based profile enhancements
- In-app chat and real-time communication
- Better recommendation logic for skill matches
- Enhanced test coverage and CI/CD integration
- Production-ready deployment pipeline

## Author

- Student Project: SkillSwap (Mobile Application Development)

## License

This project is created for academic and demonstration purposes.

