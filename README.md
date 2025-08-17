# edubot

# EduBot - AI Homework Helper for Parents 🎓

**Empower parents to be effective learning partners — no PhD required.**

EduBot is a mobile application designed to help parents confidently support their children's homework, even when they're unsure of the answer. Using AI-powered explanations, simple language, and real-world analogies, EduBot turns stressful homework moments into calm, collaborative learning experiences.

## 🎯 Mission

Whether it's 5th-grade math, middle school science, or grammar rules parents forgot, EduBot provides instant, step-by-step help through photo scanning, voice input, or text queries.

## 👥 Target Audience

- Parents of children in grades 1–9
- Guardians and grandparents helping with homework
- Homeschooling families
- Non-native English speakers
- Educators recommending tools for home support

## ✨ Key Features (MVP)

| Feature | Status | Description |
|---------|--------|-------------|
| 📱 **Home Dashboard** | ✅ Implemented | Quick actions & daily tips for parents |
| 📸 **Scan & Explain** | 🚧 In Progress | Camera interface to scan homework problems |
| 💬 **Ask a Question** | 🚧 In Progress | Type or speak questions for AI help |
| 🧠 **AI Homework Coach** | ✅ Implemented | Powered by OpenAI - explains clearly and kindly |
| 📚 **Parent-Friendly Tips** | ✅ Implemented | Daily encouragement and learning strategies |
| 📈 **Progress Tracking** | ✅ Implemented | Track daily questions and saved problems |
| 💾 **Save & Review** | ✅ Implemented | Bookmark problems for later review |

## 🛠 Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | Flutter 3.8+ |
| **State Management** | Provider |
| **AI API** | OpenAI GPT-3.5 Turbo |
| **OCR** | Google ML Kit |
| **Audio** | Flutter TTS |
| **Local Storage** | SQLite + Shared Preferences |

## 📱 App Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── homework_question.dart
│   └── explanation.dart
├── providers/                # State management
│   └── app_provider.dart
├── screens/                  # UI screens
│   ├── home_screen.dart
│   ├── scan_homework_screen.dart
│   ├── ask_question_screen.dart
│   ├── history_screen.dart
│   └── settings_screen.dart
├── services/                 # External services
│   ├── ai_service.dart
│   ├── ocr_service.dart
│   └── audio_service.dart
├── widgets/                  # Reusable components
│   ├── quick_action_card.dart
│   ├── daily_tip_card.dart
│   └── progress_summary.dart
└── utils/                    # Utilities & themes
    ├── app_theme.dart
    ├── app_config.dart
    └── environment_config.dart
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.8+
- Dart SDK 3.0+
- Android Studio / Xcode for mobile development
- OpenAI API key (for AI features)

### Quick Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd edubot
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Environment Variables** (Required for AI features)
   
   ```bash
   # Copy the environment template
   cp .env.example .env
   
   # Edit .env with your OpenAI API key
   # OPENAI_API_KEY=sk-your-actual-api-key-here
   ```
   
   📖 **For detailed setup instructions, see [SETUP.md](SETUP.md)**

4. **Run the app**
   ```bash
   flutter run
   ```

### Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Analyze code
flutter analyze
```

## 🎨 Design Philosophy

EduBot follows these core design principles:

1. **Parent-Centric**: Every feature is designed with busy, sometimes overwhelmed parents in mind
2. **Encouraging**: Never make parents feel bad for not knowing something
3. **Simple**: Clear, jargon-free explanations that anyone can understand
4. **Collaborative**: Promotes learning together rather than just giving answers
5. **Confidence-Building**: Helps parents feel more capable as learning partners

## 📊 App Flow

### Scan a Problem Flow
1. **Home** → Tap "Scan a Problem"
2. **Camera** → Align worksheet → Tap "Scan"
3. **OCR** → Extract text → Send to AI
4. **AI** → Return explanation → Display result
5. **Actions** → Save, share, or play audio

### Ask a Question Flow
1. **Home** → Tap "Ask a Question"
2. **Input** → Type or speak question
3. **AI** → Process → Return explanation
4. **Review** → Step-by-step breakdown with parent tips

## 🧩 Key Components

### AI Service
- **Model**: OpenAI GPT-3.5 Turbo (cost-effective)
- **Prompt**: Specifically designed for parent-friendly explanations
- **Features**: Step-by-step breakdowns, real-world examples, encouragement

### OCR Service
- **Engine**: Google ML Kit (on-device processing)
- **Features**: Text extraction, math recognition, noise filtering
- **Privacy**: Images processed locally, not stored

### Audio Service
- **Engine**: Flutter TTS
- **Features**: Slow, clear speech optimized for learning
- **Customization**: Adjustable speed, multiple languages

## 💡 Sample AI Output

**Input**: "Solve 3x – 7 = 8"

**Output**:
```json
{
  "answer": "x = 5",
  "steps": [
    {
      "stepNumber": 1,
      "title": "Add 7 to both sides",
      "description": "We want to get x by itself. First, let's undo the -7 by adding 7 to both sides: 3x - 7 + 7 = 8 + 7",
      "tip": "Think of it like a balance scale - whatever you do to one side, you must do to the other!",
      "isKeyStep": true
    }
  ],
  "parentFriendlyTip": "Algebra is like solving a puzzle - we're just finding what number x represents. Don't worry if it feels tricky at first!",
  "realWorldExample": "This is like figuring out how many $3 items you bought if you spent $15 total and got $7 in change.",
  "subject": "Math",
  "difficulty": "medium"
}
```

## 🗺 Roadmap

### Phase 1: MVP (Current)
- ✅ Basic UI structure
- ✅ AI integration foundation
- ✅ Daily tips and progress tracking
- 🚧 Camera integration
- 🚧 Question input interface

### Phase 2: Enhanced Features
- 📸 Advanced OCR for handwriting
- 🎤 Voice question input
- 🔊 Audio explanations
- 💾 Advanced history and bookmarking

### Phase 3: Premium Features
- 🌐 Multi-language support
- 📚 Parent refresher courses
- ⏱ Homework timer
- 📊 Learning analytics

### Phase 4: Community & Expansion
- 🏫 School partnerships
- 👨‍👩‍👧‍👦 Family accounts
- 📝 Subject-specific modules
- 🤝 Community features

## 🔒 Privacy & Security

- **COPPA Compliant**: No data collection from children under 13
- **Local Processing**: Images processed on-device when possible
- **Encrypted Storage**: User data encrypted at rest
- **Anonymous Analytics**: Optional, anonymized usage data only
- **No Image Storage**: Homework photos not permanently stored

## 🏆 Success Metrics

| Goal | Metric |
|------|--------|
| **Engagement** | Average sessions per week |
| **Helpfulness** | % "Yes" on feedback prompts |
| **Retention** | 7-day & 30-day active users |
| **Trust** | Parent confidence score surveys |
| **Learning** | Questions successfully resolved |

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new features
5. Ensure all tests pass
6. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation**: [GitHub Wiki](wiki-link)
- **Issues**: [GitHub Issues](issues-link)
- **Discussion**: [GitHub Discussions](discussions-link)
- **Email**: support@edubot.app

## 🙏 Acknowledgments

- OpenAI for providing the GPT API
- Google for ML Kit OCR capabilities
- Flutter team for the amazing framework
- All the parents testing and providing feedback

---

**Made with ❤️ for parents everywhere who want to help their children succeed in learning.**

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
