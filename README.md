# DocMobi - Healthcare Platform 🏥

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.10.4-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.10.4-0175C2?logo=dart)
![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-brightgreen)
![License](https://img.shields.io/badge/License-Proprietary-red)

**A comprehensive healthcare mobile application connecting patients with healthcare providers**

[Features](#-features) • [Installation](#-installation) • [Tech Stack](#-tech-stack) • [Contributing](#-contributing)

</div>

---

## 📋 Table of Contents

- [About](#-about)
- [Features](#-features)
- [Tech Stack](#-tech-stack)
- [Prerequisites](#-prerequisites)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Running the App](#-running-the-app)
- [Project Structure](#-project-structure)
- [Backend Integration](#-backend-integration)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🌟 About

**DocMobi** is a feature-rich healthcare platform built with Flutter that facilitates seamless communication between patients and healthcare providers. The application offers comprehensive appointment management, real-time video/audio consultations, messaging, location-based doctor discovery, and much more.

### Key Highlights

- 🎯 **Dual User Roles**: Separate interfaces for Patients and Doctors
- 📱 **Cross-Platform**: Works on iOS and Android
- 🔐 **Secure Authentication**: JWT-based authentication with secure storage
- 📞 **Real-Time Communication**: Video/audio calls and instant messaging
- 🗺️ **Location Services**: Find nearby doctors using Google Maps
- 🔔 **Smart Notifications**: Real-time push notifications with badge indicators
- 📅 **Appointment Management**: Book, manage, and track appointments
- 👨‍👩‍👧‍👦 **Family Management**: Add and manage dependents

---

## ✨ Features

### 👤 Patient Features

#### Discovery & Search
- 🏠 Personalized home dashboard
- 🔍 Advanced doctor search with filters
- 🗺️ Interactive map to find nearby doctors
- 📍 Real-time location services
- ⭐ Save favorite doctors to wishlist

#### Appointments
- 📅 Book appointments with doctors
- 📋 View appointment history
- 🔔 Real-time appointment notifications
- ℹ️ Detailed appointment information

#### Communication
- 💬 Real-time chat with doctors (Agora Chat)
- 📞 Video consultations
- 🎙️ Audio calls
- ✉️ Message history and read receipts

#### Profile & Settings
- 👤 Personal profile management
- 👨‍👩‍👧‍👦 Manage family dependents
- 🔒 Change password
- ⭐ Wishlist management
- 🆘 Help & Support

#### Content
- 🎬 Healthcare reels/video feed
- 📰 Educational content

### 👨‍⚕️ Doctor Features

#### Dashboard
- 📊 Analytics and statistics
- 📅 Upcoming appointments overview
- 📈 Earnings tracking

#### Appointment Management
- 📋 View all patient appointments
- ✅ Accept/reject appointment requests
- 🗓️ Schedule management
- 👥 Session management

#### Communication
- 💬 Chat with patients
- 📞 Video consultations
- 🎙️ Audio calls

#### Content Creation
- ✍️ Create educational posts
- 🎬 Upload reels/videos
- 📤 Share content

#### Profile
- 👤 Professional profile management
- 🗓️ Set availability schedule
- 💳 View earnings

### 🔧 Core Features

- 🔐 **Authentication**: Email/password, OTP verification, password recovery
- 🔔 **Notifications**: Push notifications, real-time polling, badge indicators
- 📱 **Responsive UI**: Material Design with smooth animations
- 🎨 **UX Enhancements**: Shimmer effects, loading states, error handling
- 🌐 **Offline Support**: Local storage and caching
- 🔒 **Security**: Secure token storage, encrypted communications

---

## 🛠️ Tech Stack

### Frontend

| Technology | Purpose |
|------------|---------|
| **Flutter 3.10.4** | Cross-platform framework |
| **Dart** | Programming language |
| **Riverpod** | State management |
| **Provider** | Dependency injection |

### Key Packages

#### UI & User Experience
- `cupertino_icons` - iOS-style icons
- `shimmer` - Loading shimmer effects
- `cached_network_image` - Image caching

#### Real-Time Communication
- `agora_rtc_engine` - Video/audio calls
- `agora_chat_sdk` - Real-time messaging
- `socket_io_client` - WebSocket communication

#### Maps & Location
- `google_maps_flutter` - Google Maps integration
- `geolocator` - Location services
- `geocoding` - Address lookup

#### Media
- `image_picker` - Image selection
- `video_player` - Video playback
- `video_thumbnail` - Thumbnail generation

#### Storage & Persistence
- `shared_preferences` - Local preferences
- `flutter_secure_storage` - Secure token storage

#### Networking
- `http` - API requests

#### Notifications
- `flutter_local_notifications` - Push notifications

#### Utilities
- `intl` - Internationalization
- `permission_handler` - Permission management
- `url_launcher` - URL handling
- `share_plus` - Content sharing
- `wakelock_plus` - Prevent screen sleep during calls

### Backend

- **Node.js** - Server runtime
- **Socket.io** - Real-time events
- **JWT** - Authentication
- **Agora** - Video/audio infrastructure

---

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK**: Version 3.10.4 or higher
- **Dart SDK**: Version 3.10.4 or higher
- **Android Studio** / **Xcode**: For building platform-specific code
- **Node.js**: Version 14.x or higher (for backend)
- **Git**: For version control

### Platform-Specific Requirements

#### iOS Development
- macOS with Xcode 14.0+
- CocoaPods installed
- iOS Simulator or physical device

#### Android Development
- Android Studio
- Android SDK (API level 21+)
- Android Emulator or physical device

---

## 🚀 Installation

### 1. Clone the Repository

```bash
git clone <repository-url>
cd theking943-flutter
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Install iOS Dependencies (macOS only)

```bash
cd ios
pod install
cd ..
```

### 4. Verify Installation

```bash
flutter doctor
```

Ensure all checkmarks are green. Fix any issues indicated by the doctor command.

---

## ⚙️ Configuration

### 1. Environment Variables

Create a `.env` file in the project root (if not already present):

```env
# Backend API
API_BASE_URL=https://your-backend-url.com/api
SOCKET_URL=https://your-backend-url.com

# Agora Credentials
AGORA_APP_ID=your_agora_app_id
AGORA_APP_CERT=your_agora_app_certificate

# Google Maps API
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
```

### 2. Google Maps Configuration

#### Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
```

#### iOS (`ios/Runner/AppDelegate.swift`)

```swift
GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
```

### 3. Agora Setup

Update the Agora App ID in your configuration files as needed.

---

## 🏃 Running the App

### Development Mode

#### iOS
```bash
flutter run -d ios
```

#### Android
```bash
flutter run -d android
```

#### Web
```bash
flutter run -d chrome
```

### Production Build

#### iOS
```bash
flutter build ios --release
```

#### Android APK
```bash
flutter build apk --release
```

#### Android App Bundle
```bash
flutter build appbundle --release
```

---

## 📁 Project Structure

```
lib/
├── config/                 # App configuration
├── l10n/                   # Localization files
├── models/                 # Data models
│   ├── appointment_model.dart
│   ├── doctor_model.dart
│   ├── user_model.dart
│   ├── message_model.dart
│   ├── notification_model.dart
│   ├── post_model.dart
│   └── dependent_model.dart
├── providers/              # Riverpod providers
├── screens/                # UI screens
│   ├── auth/              # Authentication screens
│   ├── common/            # Shared screens (calls)
│   ├── doctor/            # Doctor-specific screens
│   ├── patient/           # Patient-specific screens
│   ├── onboarding/        # Onboarding flow
│   ├── location/          # Location picker
│   └── splash/            # Splash screen
├── services/              # Business logic & API
│   ├── api_service.dart
│   ├── auth_service.dart
│   ├── agora_service.dart
│   ├── agora_chat_service.dart
│   ├── call_manager_service.dart
│   ├── appointment_service.dart
│   ├── doctor_service.dart
│   ├── notification_service.dart
│   ├── notification_poller.dart
│   ├── socket_service.dart
│   ├── location_service.dart
│   ├── directions_service.dart
│   ├── user_service.dart
│   ├── dependent_service.dart
│   ├── earnings_service.dart
│   └── doctor_schedule_service.dart
├── utils/                 # Utility functions
├── widgets/               # Reusable widgets
└── main.dart             # App entry point
```

---

## 🔗 Backend Integration

The app integrates with a Node.js backend that provides:

- RESTful API endpoints for all CRUD operations
- Socket.io server for real-time events
- WebRTC signaling for video/audio calls
- JWT authentication
- Agora token generation

### API Endpoints

The backend provides endpoints for:
- Authentication (login, register, password reset)
- User management
- Doctor profiles and search
- Appointment booking and management
- Messaging
- Notifications
- File uploads
- Earnings and analytics

Refer to the backend documentation for detailed API specifications.

---

## 🧪 Testing

### Run Unit Tests
```bash
flutter test
```

### Run Integration Tests
```bash
flutter drive --target=test_driver/app.dart
```

### Code Analysis
```bash
flutter analyze
```

---

## 📊 Quality Assurance

### Recent Improvements

✅ Fixed notification badge separation (messages vs general)  
✅ Resolved WebRTC media stream issues  
✅ Fixed notification endpoint errors  
✅ Enhanced video playback controls  
✅ Improved location service accuracy  
✅ Migrated to Riverpod state management  
✅ Implemented blue dot badge indicators  
✅ Optimized notification polling  

---

## 🤝 Contributing

### Development Workflow

1. Create a feature branch
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes and commit
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```

3. Push to your branch
   ```bash
   git push origin feature/your-feature-name
   ```

4. Create a Pull Request

### Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter analyze` to check for issues
- Format code with `dart format .`
- Write meaningful commit messages

---

## 📄 License

This project is proprietary and confidential. Unauthorized copying, distribution, or use is strictly prohibited.

---

## 👥 Team

Developed by the DocMobi Development Team

---

## 📞 Support

For technical support or questions:
- Email: support@docmobi.com
- Documentation: [Link to docs]
- Issue Tracker: [Link to issues]

---

## 🎉 Acknowledgments

- Flutter team for the amazing framework
- Agora for real-time communication infrastructure
- Google Maps Platform for location services
- All open-source contributors

---

<div align="center">

**Built with ❤️ using Flutter**

</div>
