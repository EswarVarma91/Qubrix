# Qubrix

**Adaptive AI Agent SDK for Mobile Applications**

Qubrix is a Flutter/Dart SDK that brings adaptive, personalized AI automation to mobile apps. It combines on-device model management, behavioral learning, and developer-defined action automation into a single embeddable package.

## What It Does

Qubrix enables your app to:

- **Download and run AI models** from HuggingFace, with automatic model selection that picks the smallest model capable of completing a task
- **Learn user routines** from permitted interactions — detecting repeated action sequences, time-based habits, and frequent feature usage
- **Recommend helpful actions** based on learned patterns and current context
- **Automate multi-step workflows** at three levels: suggest, prepare for review, or execute directly (with permission and confirmation gates)
- **Answer user questions** from a host-supplied Q&A knowledge base, on-device, in the user's language (multilingual: en, hi, te, nl, fr, es, etc.)
- **Protect sensitive data** with per-customer encryption, tamper detection, and secure storage

## SDK Firebase Architecture

A key architectural point: the SDK has its own Firebase configuration for Remote Config.

### SDK's Firebase (Required)

The SDK manages its own Firebase app for Remote Config. This allows the SDK to fetch the HuggingFace model URL regardless of whether the host app has Firebase or not.

- **Purpose:** Fetch the HuggingFace model URL from Firebase Remote Config
- **Configuration:** `SdkFirebaseOptions` in the SDK's codebase
- **When used:** Always — the SDK needs this for Remote Config

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

## Overview

Qubrix is a Flutter/Dart SDK that provides:

- **Model Management** — Download, verify, load, and unload AI models from HuggingFace. Models are controlled via Firebase Remote Config (`hf_model_url`). The user never selects a model; it's handled as a background task.
- **Adaptive Model Selection** — Automatically picks the smallest model capable of completing a task, considering device capabilities, quality thresholds, and resource constraints.
- **Task Orchestration** — Unified layer for executing classification, extraction, generation, summarization, and completion tasks through rule-based or model-based routing.
- **Personalization Engine (3-layer)** —
  - *Layer 1: Activity Memory* — permitted, structured facts about recent interactions
  - *Layer 2: Routine & Preference Engine* — pattern detection (sequential, temporal, usage patterns)
  - *Layer 3: AI Interpretation* — converts detected patterns into natural-language suggestions
- **Recommendation Engine** — Context-aware suggestions based on learned routines and current context (time of day, feature usage, etc.).
- **Automation Engine (3 levels)** —
  - *Level 1: Suggest* — Recommends an action
  - *Level 2: Prepare* — Prepares the action for review
  - *Level 3: Execute* — Performs an authorized action (with permission gates)
- **Compatibility Engine** — Validates models against device capabilities, OS versions, and hardware requirements.
- **Model Optimizer** — Finds the smallest model that meets task requirements, with quality vs. resource tradeoff analysis.
- **Knowledge Training (Q&A)** — On-device learning from host-supplied Q&A bundles. Multilingual answering (en, hi, te, nl, fr, es, etc.). Compact storage with LRU eviction. Host owns sync; SDK owns learning.

## Architecture

The SDK consists of 7 core components:

1. **AI Model Manager** — Handles model downloading, verification, loading, unloading
2. **Compatibility Engine** — Checks device compatibility for models
3. **Model Optimizer** — Optimizes model usage based on device resources
4. **Task Orchestrator** — Unified layer for request classification and task routing
5. **Personalization Engine** — Personalizes based on user behavior (3-layer)
6. **Recommendation Engine** — Provides personalized recommendations
7. **Automation Engine** — Executes automated tasks (3 levels: Suggest/Prepare/Execute)

Plus:
- **Knowledge Store** — On-device Q&A index for host-supplied knowledge (host owns sync, SDK owns learning)
- **Comprehensive Security Layer** — Integrity verification, tamper detection, data protection, secure storage, audit logging, and emergency breach response

## Key Features

| Feature | Description |
|---------|-------------|
| **Smallest-Valid Model Selection** | Automatically uses the smallest model that can reliably complete tasks, reducing download size, memory usage, and inference latency |
| **Personalized Learning** | Learns user routines and preferences from permitted interactions — sequential action patterns, time-based habits, and frequent feature usage |
| **Proactive Automation** | Suggests useful actions and performs multi-step workflows when authorized, at three levels: suggest, prepare for review, or execute directly |
| **On-Device Q&A** | Answers user questions from a host-supplied knowledge base, entirely on-device, in the user's language (multilingual support) |
| **Comprehensive Security** | Integrity verification, tamper detection (rooted/jailbroken/debuggers), per-customer AES-256-GCM encryption, secure storage, audit logging, and emergency breach response |
| **Firebase-Independent** | The SDK manages its own Firebase app for Remote Config, so it works regardless of whether the host app has Firebase |
| **Privacy-First** | Privacy modes (localOnly, localFirst, balanced, cloudFirst), user controls for personalization, and clear data lifecycle management |

## Security

The SDK includes a comprehensive security layer:

- **Integrity Verification** - Verifies SDK code integrity at runtime
- **Tamper Detection** - Detects tampering, rooted/jailbroken devices, debuggers
- **Data Protection** - AES-256-GCM encryption, per-customer keys (HKDF-derived)
- **Permission Guard** - Permissions for sensitive operations
- **Secure Storage** - Secure storage for sensitive data
- **Audit Logging** - Audit logging for security events
- **Emergency Response** - Automatic lockout and secure data deletion

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

## Training & Sync (host owns sync, SDK owns model + learning)

- [SDK Training Guide](docs/SDK_TRAINING_GUIDE.md) - what material the SDK learns from (JSON/XML/CSV/MD/DOC via host conversion), canonical `QaPair`/`QaTrainingBundle` shapes, multilingual same-language answering, compact storage, Firebase pointer
- [Main-App Sync Companion](docs/MAIN_APP_SYNC_COMPANION.md) - what the host app must send up (only `synced==false` Q&A, no PII), `synced` flag lifecycle, merged A-Z download, `ingestKnowledge` wiring, schedule
- Responsibility split: model choice stays SDK-only via Firebase Remote Config `hf_model_url` (`SdkFirebaseOptions`, see `dart/firebase_config_setup.md`). Q&A sync is host-only; the SDK never calls the network for training.
- SDK surface: `ingestKnowledge(bundle)`, `upsertQaPairs`, `removeQaPairs`, `askKnowledge(question, {lang})`, `knowledgeStats()`, `clearKnowledge()`, `automationHintForQa` (reuses existing `AutomationEngine`).

## Integration Guides

- [Flutter Integration](dart/INTEGRATION_FLUTTER.md) - Complete Flutter integration guide (includes Training/Q&A section)
- [Android Native Integration](dart/INTEGRATION_ANDROID_NATIVE.md) - Native Android integration guide (includes Training/Q&A section)
- [iOS Native Integration](dart/INTEGRATION_IOS_NATIVE.md) - Native iOS integration guide (includes Training/Q&A section)

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
