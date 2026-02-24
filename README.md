<div align="center">
  
# 🏥 DocMobi - The Complete Healthcare Platform
  
**Connecting Patients and Doctors Seamlessly. Anytime, Anywhere.**

[![Flutter](https://img.shields.io/badge/Flutter-3.10.4-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10.4-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-brightgreen?style=for-the-badge&logo=appveyor)](https://flutter.dev)

*Read this document to understand what DocMobi does (for everyone) and how it is built (for developers).*

</div>

---

## 🌟 What is DocMobi? (Project Overview)

**DocMobi** is a mobile application designed to make healthcare easy and accessible. Whether you are a patient looking for medical advice or a doctor managing your daily appointments, DocMobi brings the clinic right to your smartphone. 

We bridge the gap between healthcare providers and those seeking care through instant video consultations, secure messaging, and an intuitive booking system.

### 💡 Why DocMobi?
- **No More Waiting Rooms:** Consult with doctors from the comfort of your home.
- **Find the Best Care:** See doctor ratings, read reviews, and find specialists near your location.
- **Health Education:** Scroll through a TikTok-style feed of health and wellness videos created by verified doctors.

---

## ✨ Features at a Glance

### 👤 For Patients (Your Virtual Clinic)
* 🗺️ **Find Nearby Doctors:** Use the interactive map to locate the best doctors in your area.
* 📅 **Instant Appointments:** Skip the phone calls. Book, reschedule, or cancel appointments directly from the app.
* 📹 **Video & Audio Consultations:** Talk to your doctor face-to-face via secure video calls or quick audio calls.
* 👨‍👩‍👧‍👦 **Family Care:** Add your parents, children, or dependents and manage their appointments from your single account.
* 💬 **Direct Messaging:** Chat with your doctor for follow-ups and quick queries.

### 👨‍⚕️ For Doctors (Your Digital Practice)
* 📊 **Smart Dashboard:** View your daily schedule, upcoming appointments, and overall earnings at a glance.
* ⚙️ **Flexible Scheduling:** Set your own working hours, block time off, and accept or decline patient requests.
* 🎬 **Share Knowledge:** Upload short educational videos (Reels) and health articles to build your reputation and educate patients.
* 💳 **Track Earnings:** Keep track of your consultation fees and financial growth easily.

---

## � App Experience

> *(Place your app screenshots here to give viewers a visual feel of DocMobi)*

<div align="center">
  <img src="https://via.placeholder.com/250x500.png?text=Home+Screen" width="200" alt="Home Dashboard"/>
  <img src="https://via.placeholder.com/250x500.png?text=Doctor+Profile" width="200" alt="Doctor Profile"/>
  <img src="https://via.placeholder.com/250x500.png?text=Video+Call" width="200" alt="Video Consultation"/>
  <img src="https://via.placeholder.com/250x500.png?text=Appointments" width="200" alt="Appointment Booking"/>
</div>

---

<br>

<div align="center">
  <h2>💻 DEVELOPER DOCUMENTATION 💻</h2>
  <p><i>The following sections are intended for software engineers, contributors, and technical maintainers.</i></p>
</div>

---

## 🛠️ Technology Stack

DocMobi is built with modern, scalable, and high-performance technologies.

### App Frontend (Mobile App)
| Core Framework | **Flutter (3.10.4)** for cross-platform iOS & Android development |
|----------------|-------------------------------------------------------------------|
| **Language**   | Dart |
| **State Management** | Riverpod & Provider (Predictable state control) |
| **Real-Time Media** | Agora RTC Engine (For ultra-low latency Video/Audio calls) & Agora Chat |
| **Maps & Location** | Google Maps Flutter, Geolocator, Geocoding |
| **Local Services** | Firebase Cloud Messaging (FCM), Flutter CallKit Incoming |

### Backend Infrastructure
The app connects to a secure **Node.js** server environment featuring:
- **RESTful APIs:** Handling users, appointments, and data synchronization.
- **WebSockets (Socket.io):** Managing real-time events, online status, and instant updates.
- **Agora Token Server:** Securely generating tokens for communication channels.

---

## 🚀 Getting Started (Installation Guide)

Follow these steps to set up the development environment on your local machine.

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.10.4`) and Dart installed.
- Android Studio (for Android emulation) and/or Xcode (for iOS simulation on macOS).
- CocoaPods installed (for iOS dependencies).

### 1. Clone the Repository
```bash
git clone <repository-url>
cd theking943-flutter
```

### 2. Install App Dependencies
Fetch all required packages for the Flutter project:
```bash
flutter pub get
```

### 3. Setup Environment Variables
You must connect the app to your backend and third-party services. Create a `.env` file in the root directory:
```env
# Backend Server API
API_BASE_URL=https://your-backend-url.com/api
SOCKET_URL=https://your-backend-url.com

# Agora Services (For Video/Audio Calls)
AGORA_APP_ID=your_agora_app_id
AGORA_APP_CERT=your_agora_app_certificate

# Google Maps API Key
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
```

### 4. iOS Specific Setup (macOS only)
Install the strictly required iOS pods to run the app on an iPhone or simulator:
```bash
cd ios
pod install
cd ..
```

### 5. Build and Run
Ensure an emulator is running or a device is connected, then execute:
```bash
# Run the app
flutter run
```

---

## 📁 Project Architecture

The codebase is organized cleanly to separate UI, Business Logic, and Data Models:

```text
lib/
 ├── config/        # Environment setups, themes, and constants
 ├── models/        # Data structures (User model, Appointment model, etc.)
 ├── providers/     # Riverpod global state providers
 ├── screens/       # UI Pages categorized by feature (Patient, Doctor, Auth, etc.)
 ├── services/      # Core logic (API Service, Agora Service, Socket Service)
 ├── utils/         # Helper functions, time formatters, validators
 ├── widgets/       # Reusable UI components (Buttons, Cards, Dialogs)
 └── main.dart      # Application entry point
```

---

## 🧪 Quality Assurance & Testing

We uphold strong coding standards to ensure a bug-free experience.
- Ensure all new features utilize **Riverpod** correctly.
- Run `flutter analyze` before pushing code to catch potential errors or formatting issues.
- The CallKit and WebRTC systems are critical and require physical device testing for audio/video permissions and background states.

---

## 🤝 Support & License

This software is a proprietary product. Unauthorized copying, distribution, or modification is strictly prohibited. 

If you require technical support or have questions about the API integrations, please contact the development team at **support@docmobi.com**.

<div align="center">
  <p>Built with ❤️ by the <b>DocMobi Team</b></p>
</div>
