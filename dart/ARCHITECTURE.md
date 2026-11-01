# Qubrix Architecture

## Overview

Qubrix is an adaptive, personalized AI automation platform for mobile applications. It combines:

1. **Smallest capable model selection** - Automatically use the smallest model that can reliably complete tasks
2. **Personalized learning** - Learn user routines and preferences from permitted interactions
3. **Proactive automation** - Suggest useful actions and perform multi-step workflows when authorized

## Architecture Diagram

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

## Core Components

### 1. AI Model Manager (`ModelManager`)

**Responsibility:** Downloads, installs, updates, and removes models.

**Key features:**
- Model download with progress tracking
- Model installation and storage management
- Model updates and version management
- Model removal and cleanup
- Model inference execution

**API:**
```dart
final modelManager = AdaptiveAgentEngine(...).modelManager;

// Download a model
await modelManager.downloadModel(
  'small-classifier',
  deviceInfo,
);

// Check if installed
bool installed = modelManager.isModelInstalled('small-classifier');

// Run inference
final output = await modelManager.runInference(
  'small-classifier',
  {'text': 'Sample input'},
);

// Remove model
await modelManager.removeModel('small-classifier');
```

### 2. Compatibility Engine (`CompatibilityEngine`)

**Responsibility:** Validates models against device and runtime capabilities.

**Key features:**
- Device capability detection
- Model compatibility checking
- OS version compatibility
- Hardware requirement validation
- License compatibility checking

**API:**
```dart
final compatibilityEngine = AdaptiveAgentEngine(...).compatibilityEngine;

// Get device info
final deviceInfo = await compatibilityEngine.getDeviceInfo();

// Check compatibility
final result = compatibilityEngine.checkModelCompatibility(
  model,
  deviceInfo,
  preferredQuantization: QuantizationFormat.int8,
);

if (result.isCompatible) {
  // Safe to use this model
}
```

### 3. Model Optimizer (`ModelOptimizer`)

**Responsibility:** Finds the smallest model that meets task requirements.

**Key features:**
- Task-based model selection
- Candidate model evaluation
- Quality vs. resource tradeoffs
- Model recommendation with explanations
- Benchmark-based selection

**API:**
```dart
final modelOptimizer = AdaptiveAgentEngine(...).modelOptimizer;

// Find smallest suitable model
final candidate = await modelOptimizer.findSmallestSuitableModel(
  taskType: TaskType.classification,
  deviceInfo: deviceInfo,
  minQuality: 0.8,
);

// Get recommendations
final recommendations = await modelOptimizer.getRecommendations(
  TaskRequirements(
    requiresModel: true,
    complexity: TaskComplexity.low,
    minQuality: 0.7,
    preferredApproach: 'model',
  ),
);
```

### 4. Personalization Engine (`PersonalizationEngine`)

**Responsibility:** Learns permitted routines and preferences.

**Key features:**
- Activity event recording
- Pattern detection (sequential, temporal, usage)
- Routine identification
- Preference learning
- User profile management

**API:**
```dart
final personalizationEngine = AdaptiveAgentEngine(...).personalizationEngine;

// Record activity
await personalizationEngine.recordActivity(
  ActivityEvent.featureUsed(
    featureName: 'search',
    featureId: 'search_products',
  ),
);

// Get user profile
final profile = await personalizationEngine.getUserProfile();

// Get task context
final context = await personalizationEngine.getTaskContext(
  taskType: TaskType.classification,
);
```

### 5. Recommendation Engine (`RecommendationEngine`)

**Responsibility:** Suggests useful actions based on context and learned patterns.

**Key features:**
- Routine-based recommendations
- Feature usage recommendations
- Context-aware suggestions
- Recommendation acceptance/tracking
- Recommendation feedback loop

**API:**
```dart
final recommendationEngine = AdaptiveAgentEngine(...).recommendationEngine;

// Generate recommendation
final recommendation = await recommendationEngine.generateRecommendation(
  contextType: 'time_of_day',
  contextData: {'hour': 9},
);

// Accept recommendation
await recommendationEngine.acceptRecommendation(recommendation.id);

// Dismiss recommendation
recommendationEngine.dismissRecommendation(recommendation.id);
```

### 6. Automation Engine (`AutomationEngine`)

**Responsibility:** Executes approved actions through the application's supported interfaces.

**Key features:**
- Workflow execution
- Plan generation for goals
- Step-by-step execution with confirmation
- Idempotency protection
- Retry with backoff
- Permission checking

**API:**
```dart
final automationEngine = AdaptiveAgentEngine(...).automationEngine;

// Execute a workflow
final result = await automationEngine.executeWorkflow(
  'weekly_report',
  {'reportType': 'weekly'},
  requireConfirmation: true,
);

// Generate plan for a goal
final plan = await automationEngine.generatePlan(
  'Prepare weekly sales report',
);
```

### 7. Task Orchestrator (`TaskOrchestrator`)

**Responsibility:** Unified layer coordinating all components.

**Key features:**
- Request understanding and classification
- Rule-based vs. model-based routing
- Model selection and loading
- Task execution
- Feedback recording

**API:**
```dart
final orchestrator = AdaptiveAgentEngine(...).taskOrchestrator;

// Execute a task
final result = await orchestrator.orchestrateTask(
  TaskRequest(
    taskId: 'task_123',
    description: 'Classify this notification',
    input: {'text': 'Your order has shipped!'},
    taskType: TaskType.classification,
  ),
);
```

## Model Selection Pipeline

```
REGISTER TASK
        |
        v
IDENTIFY TASK REQUIREMENTS
        |
        v
CHECK RULE-BASED OPTIONS
        |
  Task solved reliably?
    /          \
  YES           NO
   |             |
   v             v
Use rules    Find candidate models
                 |
                 v
         Check model compatibility
                 |
                 v
         Evaluate task quality
                 |
                 v
          Measure performance
                 |
                 v
      Select smallest qualifying
         supported model
                 |
                 v
              Run the feature
```

### Selection Criteria

For candidate models, evaluate:

- Task-specific accuracy
- Model download size
- Runtime memory usage
- Initialization time
- Inference latency
- Energy consumption where measurable
- Hardware compatibility
- License and distribution restrictions

## Personalization Layers

### Layer 1: Activity Memory

Stores permitted, structured facts about recent interactions:
- Feature usage counts
- Filter selections
- Workflow completions
- Suggestion dismissals

### Layer 2: Routine and Preference Engine

Uses statistics, rules, and lightweight models to identify patterns:
- Sequential action patterns
- Time-based routines
- Feature usage patterns
- Preference inference

### Layer 3: AI Interpretation

A small language model converts detected patterns into natural-language suggestions:
- "You often create a report and export it immediately afterward."
- "Would you like to combine these steps into one action?"

## Automation Levels

| Level | Behavior | Example |
|-------|----------|---------|
| Level 1: Suggest | Recommends an action | Suggests creating a report |
| Level 2: Prepare | Prepares the action for review | Generates the report and opens its preview |
| Level 3: Execute | Performs an authorized action | Saves the report to the user's chosen location |

Some operations require stronger confirmation regardless of the level:
- Purchases and payments
- Money transfers
- Deleting important data
- Sending messages externally
- Sharing private documents

## Safety and Permissions Layer

Before any action runs, the platform checks:

1. Is the action registered by the developer?
2. Is the action supported on this device?
3. Has the user granted the required permissions?
4. Does the input match the action's schema?
5. Is the action reversible?
6. Does it involve an external side effect?
7. Is explicit confirmation required?
8. Can the operation be cancelled or safely retried?

For actions that change important state, use idempotency keys or equivalent protections.

## Getting Started

### Basic Integration

```dart
import 'package:qubrix/qubrix.dart';

void main() async {
  // Create and initialize the engine
  final engine = AdaptiveAgentEngine(
    config: AgentEngineConfig(
      enablePersonalization: true,
      enableAutomation: true,
      privacyMode: PrivacyMode.localFirst,
    ),
  );

  await engine.initialize();

  // Register application actions
  engine.registerActions([
    ActionDefinition(
      id: 'search',
      name: 'Search',
      description: 'Search for items',
      inputSchema: InputSchema(
        fields: {
          'query': SchemaField(
            name: 'query',
            type: SchemaFieldType.string,
            required: true,
          ),
        },
      ),
      canBeAutomated: true,
    ),
  ]);

  // Execute a task
  final result = await engine.executeTask(
    TaskRequest(
      taskId: 'task_1',
      description: 'Classify this text',
      input: {'text': 'Hello world'},
      taskType: TaskType.classification,
    ),
  );

  // Get a recommendation
  final recommendation = await engine.getRecommendation(
    contextType: 'time_of_day',
    contextData: {'hour': 9},
  );
}
```

### Shopping App Example

```dart
// Register shopping actions
engine.registerActions([
  ActionDefinition(
    id: 'search_products',
    name: 'Search Products',
    description: 'Search for products',
    inputSchema: InputSchema(...),
    canBeAutomated: true,
  ),
  ActionDefinition(
    id: 'add_to_cart',
    name: 'Add to Cart',
    description: 'Add item to cart',
    inputSchema: InputSchema(...),
    hasSideEffects: true,
    sideEffectType: SideEffectType.payment,
    requiresConfirmation: true,
    canBeAutomated: true,
  ),
  ActionDefinition(
    id: 'checkout',
    name: 'Checkout',
    description: 'Complete purchase',
    inputSchema: InputSchema(...),
    hasSideEffects: true,
    sideEffectType: SideEffectType.payment,
    requiresConfirmation: true,
    canBeAutomated: false, // Never automate checkout automatically
  ),
]);

// After user makes several purchases...
final recommendation = await engine.getRecommendation(
  contextType: 'routine',
  contextData: {'routine': 'reorder'},
);

// User accepts recommendation
if (recommendation != null) {
  await engine.acceptRecommendation(recommendation.id);

  // Prepare cart (Level 2 automation)
  final result = await engine.executeAutomation(
    recommendation.actionId!,
    {'productId': '123', 'quantity': 2},
    requireConfirmation: true, // Always confirm for payment
  );
}
```

## Privacy and Control

### User Controls

Users should be able to:
- Enable or disable personalization
- See why a suggestion was generated
- Review or clear learned preferences
- Disable individual automations
- Revoke permissions
- Require confirmation for specified actions
- Delete locally stored personalization data

### Privacy Modes

```dart
enum PrivacyMode {
  localOnly,      // All processing on-device
  localFirst,     // Prefer local, use cloud as fallback
  balanced,       // Balanced use of local and cloud
  cloudFirst,     // Cloud preferred when available
}
```

## Development Roadmap

| Phase | Deliverable | Priority |
|-------|-------------|----------|
| 1 | Android inference prototype | Essential |
| 2 | Model downloader and lifecycle manager | Essential |
| 3 | Device compatibility engine | Essential |
| 4 | Flutter SDK and chatbot sample | Essential |
| 5 | Feature packs and shared model storage | Essential |
| 6 | Developer API and basic dashboard | Essential |
| 7 | Smallest-capable-model selection | Core differentiator |
| 8 | Local activity events and preference storage | Core differentiator |
| 9 | Routine detection and personalized suggestions | Core differentiator |
| 10 | Developer-defined action registry | Core differentiator |
| 11 | Validated automation engine and permissions | Core differentiator |
| 12 | Real-device benchmark laboratory | Ongoing |
| 13 | iOS support | Expansion |
| 14 | React Native support | Expansion |
| 15 | Advanced predictive optimization | Later |
| 16 | Enterprise deployment and private registries | Commercial |

## Best Practices

1. **Start small:** Register only essential actions first
2. **Require confirmation:** Always require explicit confirmation for payment and data deletion
3. **Use smallest model:** Let the engine select the smallest capable model
4. **Respect privacy:** Use `localFirst` privacy mode by default
5. **Track feedback:** Record which recommendations are accepted/dismissed
6. **Test on low-end devices:** Ensure compatibility with various device classes
7. **Handle failures gracefully:** Design workflows to be cancellable and retryable
