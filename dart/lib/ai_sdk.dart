// Adaptive AI Agent Engine SDK
//
// A comprehensive on-device AI SDK for adaptive, personalized AI automation
// in mobile applications.
//
// Core components:
// - Agent Engine: Orchestrates all AI operations
// - Model Manager: Downloads, installs, manages AI models
// - Task Orchestrator: Routes tasks to appropriate models
// - AI Model Manager: Model selection and lifecycle
// - Compatibility Engine: Device-model compatibility checks
// - Model Optimizer: Selects optimal model for task
// - Personalization Engine: Learns user preferences
// - Recommendation Engine: Suggests actions based on context
// - Automation Engine: Executes automated workflows
// - Security: Encryption, integrity, protection

library ai_sdk;

export 'src/agent/agent_engine.dart';
export 'src/agent/task_orchestrator.dart';
export 'src/model/model_manager.dart';
export 'src/model/model_types.dart';
export 'src/model/model_catalog.dart';
export 'src/model/model_selector.dart';
export 'src/model/model_integrity_checker.dart';
export 'src/core/compatibility_engine.dart';
export 'src/core/model_optimizer.dart';
export 'src/core/personalization_engine.dart';
export 'src/core/recommendation_engine.dart';
export 'src/core/automation_engine.dart';
export 'src/core/security/security_config.dart';
export 'src/core/security/integrity_verifier.dart';
export 'src/core/security/permission_guard.dart';
export 'src/core/security/tamper_detector.dart';
export 'src/core/security/data_protector.dart';
export 'src/core/security/customer_data_protector.dart';
export 'src/core/security/data_isolation.dart';
export 'src/core/security/emergency_breach_response.dart';
