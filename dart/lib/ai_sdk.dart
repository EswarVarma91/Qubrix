/// AI SDK - Adaptive AI Agent Engine
///
/// An adaptive, personalized AI automation platform for mobile applications.
///
/// This library provides:
/// 1. Adaptive model delivery - smallest validated model for tasks
/// 2. Automatic compatibility management
/// 3. Personalized assistance - learns permitted in-app routines
/// 4. Safe application automation - combines developer-defined actions

library ai_sdk;

// Core types
export 'src/core/types.dart';

// Security
export 'src/core/security/security_config.dart';
export 'src/core/security/integrity_verifier.dart';
export 'src/core/security/permission_guard.dart';
export 'src/core/security/tamper_detector.dart';
export 'src/core/security/data_protector.dart';

// Model management
export 'src/model/model_types.dart';
export 'src/model/model_manager.dart';
export 'src/model/compatibility_engine.dart';
export 'src/model/model_catalog.dart';
export 'src/model/model_optimizer.dart';

export 'src/model/model_manager.dart' show ModelProgress, ModelOperationType;

// Personalization
export 'src/personalization/activity_event.dart';
export 'src/personalization/profile_manager.dart';
export 'src/personalization/personalization_engine.dart';
export 'src/personalization/recommendation_engine.dart';

// Automation
export 'src/automation/action_registry.dart';
export 'src/automation/permission_manager.dart';
export 'src/automation/automation_engine.dart';

// Main engine
export 'src/agent/agent_engine.dart';

// Version
export 'src/version.dart';
