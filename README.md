# Qubrix

An adaptive, personalized AI automation platform for mobile applications.

## Overview

Qubrix is a Flutter/Dart package that provides adaptive AI capabilities including:
- Model management (download, verify, load, unload from HuggingFace)
- Task execution with multiple task types
- Personalization engine (3-layer: Preferences, History, Behavior Patterns)
- Recommendation engine (personalized suggestions)
- Automation engine (3 levels: Suggest, Prepare, Execute)
- Compatibility engine (device capability checking)
- Model optimizer (resource-aware model selection)

## Architecture

The SDK consists of 6 core engines:

1. **AI Model Manager** - Handles model downloading, verification, loading, unloading
2. **Compatibility Engine** - Checks device compatibility for models
3. **Model Optimizer** - Optimizes model usage based on device resources
4. **Personalization Engine** - Personalizes based on user behavior (3-layer)
5. **Recommendation Engine** - Provides personalized recommendations
6. **Automation Engine** - Executes automated tasks (3 levels)

Plus a comprehensive security layer.

## Security

The SDK includes a comprehensive security layer:

- **Integrity Verification** - Verifies SDK code integrity at runtime
- **Tamper Detection** - Detects tampering, rooted/jailbroken devices, debuggers
- **Data Protection** - AES-256-GCM encryption, per-customer keys (HKDF-derived)
- **Permission Guard** - Permissions for sensitive operations
- **Secure Storage** - Secure storage for sensitive data
- **Audit Logging** - Audit logging for security events
- **Emergency Response** - Automatic lockout and secure data deletion

## SDK Firebase Configuration

**The SDK has its own Firebase configuration for Remote Config.**

This is a key architectural point:

### SDK's Firebase (Required)

The SDK manages its own Firebase app for Remote Config. This allows the SDK to fetch the HuggingFace model URL regardless of whether the host app has Firebase or not.

- **Purpose:** Fetch the HuggingFace model URL from Firebase Remote Config
- **Configuration:** `SdkFirebaseOptions` in the SDK's codebase
- **When used:** Always - the SDK needs this for Remote Config

### Host App's Firebase (Optional)

The host app (WhatsApp, Instagram, or any custom app) may have its own Firebase project for its own features (analytics, auth, crashlytics, etc.).

- **Purpose:** Host app features
- **Configuration:** Host app's Firebase project
- **When used:** Only if the host app wants Firebase features

### Firebase Configuration Hierarchy

1. If host app provides Firebase with Remote Config for model URL → SDK can use host app's Firebase (optional)
2. If host app has Firebase but no Remote Config for model URL → SDK uses its own Firebase
3. If host app has no Firebase → SDK uses its own Firebase

This ensures the SDK always has access to Remote Config for fetching the HuggingFace model URL.

## Getting Started

### Prerequisites

- Flutter SDK (>= 3.16.0)
- Dart SDK (>= 3.0.0)

### Installation

Add the SDK to your `pubspec.yaml`:

```yaml
dependencies:
  qubrix:
    path: ../path/to/qubrix
```

Or for published version:

```yaml
dependencies:
  qubrix: ^1.0.0
```

### Usage

```dart
import 'package:qubrix/qubrix.dart';

void main() async {
  // Initialize the SDK
  final engine = AdaptiveAgentEngine();
  await engine.initialize();

  // Download a model (uses SDK's Firebase Remote Config for URL)
  await engine.downloadModel('model-id', onProgress: (progress) {
    print('${progress.operation} ${progress.percent}%');
  });

  // Execute a task
  final result = await engine.executeTask(TaskRequest(
    taskId: 'task_1',
    description: 'Classify this text',
    input: {'text': 'Hello world'},
    taskType: TaskType.classification,
  ));

  print('Result: ${result.output}');
}
```

## Example App

See the `example/` directory for a complete Flutter example application.

### Running the Example

```bash
cd example
flutter pub get
flutter run
```

The example app demonstrates:
- GetX state management
- get_it dependency injection
- Responsive UI (mobile/tablet)
- Reusable widgets
- Security status display
- Model download with progress
- Task execution

## Integration Guides

- [Flutter Integration](INTEGRATION_FLUTTER.md) - Complete Flutter integration guide
- [Android Native Integration](INTEGRATION_ANDROID_NATIVE.md) - Native Android integration guide
- [iOS Native Integration](INTEGRATION_IOS_NATIVE.md) - Native iOS integration guide

## Project Structure

```
dart/
├── lib/
│   ├── qubrix.dart              # Main export file
│   └── src/
│       ├── agent/               # AdaptiveAgentEngine
│       ├── model/               # Model management
│       ├── engine/              # Core engines
│       ├── privacy/             # Privacy management
│       ├── security/            # Security layer
│       ├── firebase/            # SDK's Firebase config
│       ├── common/              # Types and constants
│       └── api.dart             # Public API
├── example/                     # Example Flutter app
├── test/                        # Tests
└── INTEGRATION_*.md             # Integration guides
```

## Model Source

Models are downloaded from HuggingFace. The model URL comes from Firebase Remote Config (SDK's Firebase).

**The user never selects a model - it's a background task.**

The model URL in Firebase Remote Config should be in the format:
```
https://huggingface.co/<owner>/<repo>
```

Example: `https://huggingface.co/facebook/opt-1.3b`

## Security Model

The SDK is designed with security-first principles:

### Customer Data Protection
- Each customer has a unique encryption key derived via HKDF
- Data is encrypted with AES-256-GCM
- Customer data is isolated between customers
- Data never leaves the device unless explicitly authorized

### Tamper Detection
- Detects debugging, emulation, reverse engineering
- Detects rooting/jailbreaking
- Detects SDK integrity violations
- Automatic response on detection

### Permission System
- Operation-based permissions
- User consent required for sensitive operations
- Permissions can be delegated to trusted services

## License

MIT License - see LICENSE file for details.

## Contributing

Contributions are welcome! Please read CONTRIBUTING.md for details.

## Support

For questions or issues, please open an issue on the GitHub repository.
