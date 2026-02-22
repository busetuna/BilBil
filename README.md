# 🐦 Bilbil - AI-Powered Early Childhood Learning App

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.10.4+-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.10.4+-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)

**An adaptive language learning mobile application for children aged 2-5**

[Features](#-features) • [Architecture](#-architecture) • [Getting Started](#-getting-started)

</div>

---

## 📖 About The Project

Bilbil is an innovative early childhood education application that uses artificial intelligence to create personalized learning experiences for young children. The app combines modern AI technologies to make language learning fun and effective:

- 🤖 **Reinforcement Learning** - Adapts to each child's learning pace and style
- 🎤 **Speech Recognition** - Interactive pronunciation practice and feedback
- 🔊 **Text-to-Speech** - Clear audio guidance and word pronunciation
- 📊 **Progress Tracking** - Detailed analytics for parents to monitor development

Meet **Bilbil**, a friendly blue bird character that guides children through engaging activities, making learning feel like play!

### 🎯 Perfect For
- Children aged 2-5 years old
- Early language development
- Vocabulary building
- Pronunciation practice
- Visual and auditory learning styles
- Parents who want to track learning progress


---

## ✨ Features

### 🎯 For Children
- **Smart Learning Path**: AI adapts difficulty based on child's performance
- **Voice Interaction**: Speak words and get instant feedback on pronunciation
- **Rich Content Library**: 
  - 🐾 Animals and their sounds
  - 🎨 Colors and shapes
  - 🍎 Fruits and vegetables
  - 👕 Clothing items
  - 🌤️ Weather conditions
  - 🏃 Action verbs
  - 💭 Adjectives and emotions
  - 👂 Body parts
  - 🏠 Daily objects
- **Gamified Learning**: Points, achievements, and progress milestones
- **Audio-Visual Learning**: Every word comes with image and sound
- **Safe & Ad-Free**: No ads, no in-app purchases, child-safe environment

### 👨‍👩‍👧 For Parents
- **Detailed Analytics**: Track learning progress with beautiful charts
- **Session History**: Review what your child learned each day
- **Time Management**: Set daily learning time limits
- **Performance Insights**: Understand strengths and areas to improve
- **Multiple Profiles**: Support for multiple children in one account
- **Offline Mode**: Learning continues even without internet

### 🎨 Design & Experience
- **Child-Friendly Interface**: Large buttons, bright colors, intuitive navigation
- **Material 3 Design**: Modern, smooth, and responsive UI
- **Custom Typography**: Easy-to-read fonts optimized for young children
- **Smooth Animations**: Delightful transitions and feedback
- **Bilbil Character**: A friendly blue bird that guides and encourages

---

## 🏗️ Architecture

The project follows **Clean Architecture** principles with clear separation of concerns:

```
lib/
├── core/
│   ├── constants/
│   ├── theme/
│   ├── utils/
│   └── widgets/
├── features/
│   ├── authentication/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── learning/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── onboarding/
│   └── parent_dashboard/
└── main.dart
```

### 🔧 Technology Stack

| Category | Technology |
|----------|-----------|
| **Framework** | Flutter 3.10.4+ |
| **Language** | Dart 3.10.4+ |
| **State Management** | Provider |
| **Local Storage** | Hive + Hive Flutter |
| **Authentication** | Firebase Auth (hybrid with Hive) |
| **AI Services** | Flutter TTS, Speech-to-Text |
| **Charts & Analytics** | FL Chart |
| **Animations** | Animations Package |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.10.4 or higher)
- Dart SDK (3.10.4 or higher)
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/bilbil.git
   cd bilbil
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate Hive adapters**
   ```bash
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### 🔐 Firebase Setup (Optional)

For cloud-based features, configure Firebase:

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add your Android/iOS app to the project
3. Download and add configuration files:
   - Android: `google-services.json` → `android/app/`
   - iOS: `GoogleService-Info.plist` → `ios/Runner/`

---

## 📂 Project Structure

### Key Directories

```
assets/
├── images/
│   ├── animals/          # Animal learning assets
│   ├── actions/          # Action verb visuals
│   ├── adjectives/       # Descriptive word images
│   ├── body_parts/       # Body part illustrations
│   ├── clothes/          # Clothing items
│   ├── colors/           # Color learning
│   ├── daily_objects/    # Common objects
│   ├── fruits_vegetables/# Food items
│   ├── shapes/           # Geometric shapes
│   └── weather/          # Weather conditions
├── sounds/               # Audio files
└── models/               # AI model files
```

### Feature Modules

- **Authentication**: Login, registration, password reset with hybrid storage
- **Onboarding**: First-time user experience
- **Learning**: Core educational activities with AI adaptation
- **Parent Dashboard**: Progress tracking and analytics

---

## 🎨 Design System

### Typography
- **Headers**: Fredoka (playful, child-friendly)
- **Buttons**: Quicksand (clean, readable)
- **Body Text**: Poppins (professional, clear)

### Theme
- Material 3 design system
- Custom color palette optimized for children
- Gradient backgrounds with animated elements
- Accessibility-focused contrast ratios

---

## 🎯 App Capabilities

### Currently Available
- ✅ User authentication and account management
- ✅ Beautiful animated splash screen
- ✅ Secure login and registration
- ✅ Password reset functionality
- ✅ Organized content categories
- ✅ Offline data storage
- ✅ Clean, intuitive interface

### Coming Soon
- 🔜 Interactive learning activities
- 🔜 Voice recognition games
- 🔜 Parent dashboard with analytics
- 🔜 Progress tracking and reports
- 🔜 Achievement system
- 🔜 Audio pronunciation guide

---

## 🧪 Development

### Running Tests
```bash
flutter test
```

### Code Generation
```bash
# Generate Hive adapters
flutter packages pub run build_runner build

# Watch mode for continuous generation
flutter packages pub run build_runner watch
```

### Linting
```bash
flutter analyze
```

---

## 📱 Permissions

The app requires the following permissions:
- **Microphone**: For speech recognition features
- **Storage**: For caching learning content
- **Internet**: For Firebase authentication and updates

---
## 🙏 Acknowledgments

- Flutter and Firebase communities for excellent tools and documentation
- Parents and educators who provided valuable feedback
- Early childhood education research that informed our approach

---

<div align="center">

**Made with ❤️ for early learners**

🐦 Bilbil - Where Learning Takes Flight

</div>
