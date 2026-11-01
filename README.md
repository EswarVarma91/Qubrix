# AI SDK - Adaptive AI Agent Engine

An adaptive, personalized AI automation platform for mobile applications.

## Overview

This SDK is a Flutter/Dart package that provides an adaptive, personalized AI automation engine. It downloads and manages AI models from HuggingFace, runs AI tasks locally, and learns user preferences.

## Key Features

### 1. Background Model Management
- Models are configured via **Firebase Remote Config** (no user selection)
- Only the HuggingFace URL is stored in Firebase (`hf_model_url` parameter)
- User taps a single "Download" button - SDK handles everything in background
- Download progress and model loading progress shown via callbacks

### 2. Security-First Design
- **NO user-entered secrets** - device-bound master key (random 256-bit)
- Biometric gated access (not key derivation)
- Per-customer keys via HKDF(master_key, customerId, salt)
- AES-256-GCM encryption for customer data
- Secure storage, audit logging, model tamper protection, secure delete
- Emergency breach response with auto-lockdown

### 3. Adaptive AI Agent Engine
- **AI Model Manager** - Downloads/manages models from HuggingFace
- **Compatibility Engine** - Validates models against device capabilities
- **Model Optimizer** - Finds smallest model meeting quality requirements
- **Personalization Engine** (3-layer) - Learns from app-provided events
- **Recommendation Engine** - Suggests actions based on context
- **Automation Engine** (3 levels: Suggest/Prepare/Execute) - Executes workflows
- **Task Orchestrator** - Unified coordination layer

### 4. Privacy-First
- Learn only from app-provided events
- Local processing option
- Purchases/deletions/payments require explicit confirmation

## Architecture

```
MOBILE APPLICATION
       |
    YOUR SDK (Flutter/Dart)
       |
  TASK ORCHESTRATOR
       |
  +----+----+----------------------------+
  |         |                            |
  v         v                            v
MODEL   PERSONALIZATION              ACTION REGISTRY
MANAGER    ENGINE                       |
  |         |                           v
  v         v                      AUTOMATION ENGINE
COMPATIBILITY  RECOMMENDATION          (Suggest/Prepare/Execute)
  ENGINE         ENGINE
  |               |
  +---------------+----
                  |
            MODEL SELECTION
                  |
        +---------+---------+
        |         |         |
        v         v         v
     RULES    SMALLEST   LARGER
              CAPABLE    MODEL
              MODEL
                  |
             VALIDATION
                  |
            EXECUTION
```

## Project Structure

```
.
├── dart/
│   ├── lib/
│   │   └── src/
│   │       ├── agent/         # Task orchestrator, agent engine
│   │       ├── model/         # Model manager, compatibility, optimizer
│   │       ├── personalization/ # Personalization engine
│   │       ├── recommendation/ # Recommendation engine
│   │       ├── automation/    # Automation engine
│   │       ├── core/          # Security, types, utilities
│   │       └── ai_sdk.dart    # Main library export
│   └── pubspec.yaml
│
├── dart/example/
│   ├── lib/
│   │   ├── core/              # Constants, routes, Firebase config
│   │   ├── data/              # Repositories
│   │   ├── ui/                # Screens, widgets, controllers (GetX)
│   │   └── main.dart          # App entry point
│   └── pubspec.yaml
│
└── README.md
```

## Example App

The example app demonstrates the SDK with:

- **GetX** state management + **get_it** for dependency injection
- **Responsive UI**: Tablet (2-column) + Mobile (single column)
- **Reusable widgets**: AdaptiveButton, StatusCard, ActionGrid, ModelProgressIndicator
- **Centralized constants**: AppColors, AppStrings, AppTheme
- **AppRoutes/AppPages**: Centralized routing

### Home Screen

- Status card showing app state
- Security status (protected/not compromised)
- Cloud download button (Icons.cloud_download)
- Action buttons: Run Task, Get Recommendation, Check Health
- Model progress indicator during download

### Settings Screen

- Security configuration
- Firebase setup status
- Model management

## Firebase Remote Config Setup

The app uses Firebase Remote Config to get the HuggingFace model URL:

1. Add Firebase to your project:
   - Android: `google-services.json` in `android/app/`
   - iOS: `GoogleService-Info.plist` in `ios/Runner/`

2. In Firebase console, add a parameter:
   - Key: `hf_model_url`
   - Value: HuggingFace model URL (e.g., `https://huggingface.co/facebook/demo-model`)

3. Add dependencies to `dart/example/pubspec.yaml`:
   ```yaml
   dependencies:
     firebase_core: ^latest
     firebase_remote_config: ^latest
   ```

4. Initialize Firebase in `main.dart` before using the SDK.

**Note**: When Firebase is not configured, the app falls back to a local default URL.

## User Flow

```
1. User opens app
   └─> App loads (Firebase not checked yet)

2. User taps "Download Model" (cloud icon)
   └─> Check if any model is installed
       ├─> If YES: Show "Model already installed" - skip Firebase
       └─> If NO: 
           ├─> Fetch HuggingFace URL from Firebase Remote Config
           ├─> Extract repo ID from URL
           └─> Download model from HuggingFace
               ├─> Show download progress
               ├─> Show verification progress
               ├─> Show loading progress
               └─> Show "Model ready"

3. User can now run tasks with the model
```

**The user never sees or selects a model - it's a background task.**

## Security Components

| Component | Purpose |
|-----------|----------|
| SecurityConfig | Central security configuration |
| IntegrityVerifier | Verify SDK binary integrity |
| PermissionGuard | Request/check permissions |
| TamperDetector | Detect tampering attempts |
| DataProtector | Encrypt/decrypt data |
| CustomerDataProtector | Per-customer AES-256-GCM |
| DataIsolation | Per-customer session isolation |
| EmergencyBreachResponse | Auto-lockdown on breach |
| SecureStorageManager | Platform-backed key storage |
| AuditLogger | Tamper-evident logging |
| ModelTamperProtection | Anti-rollback, substitution detection |
| SecureDeleteManager | Multi-pass overwrite, memory wipe |
| ModelIntegrityChecker | Handle model change scenarios |

## Model Change Scenarios

The SDK handles these scenarios without losing customer data:

- HuggingFace deletes/updates a model
- User clears cache or fresh installs app
- Model files become corrupted

Customer data remains safe via encryption and key isolation.

## Getting Started

See `dart/pubspec.yaml` for the Flutter SDK package.

## Integration Guides

### Flutter Integration
See [`dart/INTEGRATION_FLUTTER.md`](dart/INTEGRATION_FLUTTER.md) for:
- Adding AI SDK as a Flutter package dependency
- Using GetX + get_it for state management
- Firebase Remote Config setup
- Complete user flow documentation

### Android Native Integration
See [`dart/INTEGRATION_ANDROID_NATIVE.md`](dart/INTEGRATION_ANDROID_NATIVE.md) for:
- Flutter module integration in native Android apps
- Platform channels for native Android
- Firebase setup for Android
- Handling callbacks from Flutter

### iOS Native Integration
See [`dart/INTEGRATION_IOS_NATIVE.md`](dart/INTEGRATION_IOS_NATIVE.md) for:
- Flutter module integration in native iOS apps
- Platform channels for native iOS
- Firebase setup for iOS (GoogleService-Info.plist)
- Handling callbacks from Flutter

## Documentation Index

| Document | Description |
|----------|-------------|
| `dart/INTEGRATION_FLUTTER.md` | Flutter integration guide |
| `dart/INTEGRATION_ANDROID_NATIVE.md` | Android native integration guide |
| `dart/INTEGRATION_IOS_NATIVE.md` | iOS native integration guide |
| `dart/example/lib/core/firebase_setup.dart` | Firebase setup helper (Dart) |

## Development Roadmap

- Phase 1: Android inference prototype
- Phase 2: Model downloader and lifecycle manager
- Phase 3: Device compatibility engine
- Phase 4: Flutter SDK and chatbot sample
- Phase 5: Feature packs and shared model storage
- Phase 6: Developer API and basic dashboard
- Phase 7: Smallest-capable-model selection
- Phase 8: Local activity events and preference storage
- Phase 9: Routine detection and personalized suggestions
- Phase 10: Developer-defined action registry
- Phase 11: Validated automation engine and permissions
- Phase 12: Real-device benchmark laboratory
- Phase 13: iOS support
- Phase 14: React Native support
- Phase 15: Advanced predictive optimization
- Phase 16: Enterprise deployment and private registries
