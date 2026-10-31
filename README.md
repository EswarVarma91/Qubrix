# AI SDK - Adaptive AI Agent Engine

An adaptive, personalized AI automation platform for mobile applications.

## Overview

This SDK evolves from an on-device AI SDK into an adaptive, personalized AI automation platform. It combines:

1. **Smallest capable model selection** - Automatically use the smallest model that can reliably complete tasks
2. **Personalized learning** - Learn user routines and preferences from permitted interactions
3. **Proactive automation** - Suggest useful actions and perform multi-step workflows when authorized

## Architecture

### Core Components

```
MOBILE APPLICATION
                    |
               YOUR SDK
                    |
          TASK ORCHESTRATOR
                    |
    +---------------+------------------+
    |               |                  |
    v               v                  v
MODEL MANAGER  PERSONALIZATION    ACTION REGISTRY
    |            ENGINE               |
    v               |                  |
COMPATIBILITY       v                  v
   ENGINE       RECOMMENDATION     AUTOMATION
    |              ENGINE              ENGINE
    |               |                  |
    +---------------+------------------+
                    |
            MODEL SELECTION
                    |
      +-------------+-------------+
      |             |             |
      v             v             v
   RULES        SMALL MODEL    LARGER MODEL
      |             |             |
      +-------------+-------------+
                    |
             VALIDATION LAYER
                    |
            AUTHORIZED EXECUTION
                    |
            RESULT AND FEEDBACK
```

## Components

### 1. AI Model Manager
Downloads, installs, updates, and removes models.

### 2. Compatibility Engine
Validates models against device and runtime capabilities.

### 3. Model Optimizer
Finds the smallest model that meets task requirements.

### 4. Personalization Engine
Learns permitted routines and preferences.

### 5. Recommendation Engine
Suggests useful actions based on context and learned patterns.

### 6. Automation Engine
Executes approved actions through the application's supported interfaces.

### 7. Task Orchestrator
Unified layer coordinating all components.

## Getting Started

See `dart/pubspec.yaml` for the Flutter SDK package.

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
