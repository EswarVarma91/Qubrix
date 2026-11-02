# Qubrix Example App

A complete Flutter sample application demonstrating Qubrix integration.

Qubrix is an adaptive AI agent SDK for mobile apps that combines on-device model management, behavioral learning, and developer-defined action automation.

## What the Example Demonstrates

The example app shows how to integrate Qubrix into a Flutter application and use its core capabilities:

### Core SDK Features

- **Model Management**: Download AI models from HuggingFace via Firebase Remote Config
- **Task Execution**: Run classification, extraction, generation, summarization, and completion tasks
- **Personalization**: Record user activity and let the SDK learn routines
- **Recommendations**: Get context-aware suggestions based on learned patterns
- **Automation**: Execute multi-step workflows at three levels (Suggest/Prepare/Execute)
- **Knowledge Q&A**: Ingest knowledge bundles and answer user questions on-device
- **Security**: Tamper detection, integrity verification, secure storage, and permission guards

### App Architecture

- **GetX State Management**: Reactive UI with GetX controllers
- **get_it Dependency Injection**: Clean architecture with dependency injection
- **Responsive UI**: Adaptive layout for mobile and tablet
- **Reusable Widgets**: AdaptiveButton, StatusCard, ActionGrid, ModelProgressIndicator

## Project Structure

```
dart/example/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── core/
│   │   ├── bindings/               # GetX bindings
│   │   ├── constants/              # App strings and colors
│   │   ├── firebase_remote_config.dart
│   │   ├── firebase_setup.dart
│   │   ├── model_catalog.dart      # HuggingFace model catalog
│   │   ├── theme/                  # App theme
│   │   └── utils/                 # Router
│   ├── data/
│   │   └── repositories/          # Data repositories
│   └── ui/
│       ├── controllers/           # GetX controllers
│       ├── screens/               # Screens
│       └── widgets/               # Reusable widgets
├── android/                       # Android native project
├── ios/                           # iOS native project
└── test/                          # Unit tests
```

## Getting Started

### Prerequisites

- Flutter SDK >= 3.16.0
- Dart SDK >= 3.0.0
- Firebase project configured (for Remote Config)

### Setup

1. Add Firebase config files:
   - Android: `google-services.json` in `android/app/`
   - iOS: `GoogleService-Info.plist` in `ios/Runner/`

2. Configure Firebase Remote Config:
   - Parameter: `hf_model_url`
   - Value: HuggingFace model URL (e.g., `https://huggingface.co/facebook/demo-model`)

3. Run the app:
   ```bash
   cd dart/example
   flutter pub get
   flutter run
   ```

## User Flow

The app implements a background task flow with no model selection UI:

1. User opens app → sees "Download Model" button with cloud icon
2. User taps "Download Model"
3. App checks Firebase Remote Config for `hf_model_url` (only if no model installed)
4. App extracts repo ID from URL
5. App downloads model from HuggingFace with progress updates
6. Model is verified and loaded into memory
7. User can now run AI tasks

**The user never sees or selects a model - it's a background task.**

## Key Components

### Home Screen
- Status card showing app status
- Security status card
- Model progress indicator (download/loading)
- Action grid with quick actions
- Model status section

### Actions
- **Download Model**: Downloads from HuggingFace via Firebase config
- **Run Task**: Executes AI task with loaded model
- **Get Recommendation**: Gets personalized suggestion
- **Check Health**: Checks system health status

### Responsive Layout
- **Mobile**: Single column layout
- **Tablet**: 2-column layout (main content + actions panel)

## Dependencies

- `qubrix`: Path dependency to the SDK
- `get`: ^4.6.6 - State management
- `get_it`: ^7.6.7 - Dependency injection

## Platform Support

- Android (api 21+)
- iOS (12.0+)

## Troubleshooting

### Firebase not configured
- Add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
- Update Firebase Remote Config with `hf_model_url` parameter

### Model download fails
- Check network connectivity
- Verify HuggingFace model URL is valid
- Check device storage availability
