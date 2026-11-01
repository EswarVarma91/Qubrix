// Copyright (c) 2024 Qubrix Contributors. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

/// Adaptive AI Agent SDK
///
/// An adaptive, personalized AI automation platform for mobile applications.
///
/// ## Architecture Overview
///
/// The SDK consists of 6 core engines:
/// - [AdaptiveAgentEngine] - Main orchestrator that coordinates all engines
/// - [ModelManager] - Handles model downloading, verification, loading
/// - [CompatibilityEngine] - Checks device compatibility for models
/// - [ModelOptimizer] - Optimizes model usage for device constraints
/// - [PersonalizationEngine] - Personalizes based on user behavior (3-layer)
/// - [RecommendationEngine] - Provides personalized recommendations
/// - [AutomationEngine] - Executes automated tasks (3 levels: Suggest/Prepare/Execute)
///
/// ## Security Architecture
///
/// The SDK includes a comprehensive security layer:
/// - [SecurityConfig] - Security configuration settings
/// - [IntegrityVerifier] - Verifies SDK integrity
/// - [PermissionGuard] - Permission check for sensitive operations
/// - [TamperDetector] - Detects tampering attempts
/// - [DataProtector] - Data protection utilities
/// - [CustomerDataProtector] - Per-customer data isolation and encryption
/// - [DataIsolation] - Customer data isolation between customers
/// - [EmergencyBreachResponse] - Emergency response for security breaches
/// - [SecureStorageManager] - Secure storage for sensitive data
/// - [AuditLogger] - Audit logging for security events
/// - [ModelTamperProtection] - Model-specific tamper protection
/// - [SecureDeleteManager] - Secure deletion of sensitive data
/// - [ModelIntegrityChecker] - Model integrity verification
///
/// ## Firebase Integration
///
/// The SDK includes its own Firebase configuration for Remote Config.
/// This allows the SDK to fetch the HuggingFace model URL from Firebase
/// Remote Config regardless of whether the host app has its own Firebase
/// configuration or not.
///
/// See [SdkFirebaseInitializer] for SDK Firebase initialization and
/// [SdkRemoteConfigService] for Remote Config operations.
///
/// ## Usage
///
/// ```dart
/// // Initialize the SDK
/// final engine = AdaptiveAgentEngine();
/// await engine.initialize();
///
/// // The SDK automatically initializes Firebase for Remote Config
/// // and fetches the HuggingFace model URL
///
/// // Download a model (uses Firebase config for model URL)
/// await engine.downloadModel('model-id', onProgress: (progress) {
///   print('${progress.operation} ${progress.percent}%');
/// });
///
/// // Execute a task
/// final result = await engine.executeTask(TaskRequest(
///   taskId: 'task_1',
///   description: 'Classify this text',
///   input: {'text': 'Hello world'},
///   taskType: TaskType.classification,
/// ));
/// ```
library qubrix;

export 'package:flutter/foundation.dart' show kIsWeb;
export 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

// Core types (task types, device info, progress, health)
export 'src/core/types.dart';

// Task orchestration
export 'src/task_orchestrator.dart';

// Main public API
export 'src/agent/agent_engine.dart';

// Model management
export 'src/model/model_manager.dart';
export 'src/model/model_catalog.dart';
export 'src/model/model_types.dart';
export 'src/model/compatibility_engine.dart';
export 'src/model/model_optimizer.dart';
export 'src/model/model_integrity_checker.dart';

// Personalization
export 'src/personalization/activity_event.dart';
export 'src/personalization/personalization_engine.dart';
export 'src/personalization/recommendation_engine.dart';
export 'src/personalization/profile_manager.dart';

// Automation
export 'src/automation/action_registry.dart';
export 'src/automation/permission_manager.dart';
export 'src/automation/automation_engine.dart';

// Security
export 'src/model/permissions.dart' show SecurityPermissionLevel;
export 'src/core/security/security_config.dart';
export 'src/core/security/permission_guard.dart';
export 'src/core/security/tamper_detector.dart';
export 'src/core/security/integrity_verifier.dart';
export 'src/core/security/data_protector.dart';
export 'src/core/security/customer_data_protector.dart';
export 'src/core/security/data_isolation.dart';
export 'src/core/security/emergency_breach_response.dart';
export 'src/core/security/secure_storage_manager.dart';
export 'src/core/security/audit_logger.dart';
export 'src/core/security/model_tamper_protection.dart';
export 'src/core/security/secure_delete_manager.dart';

// Firebase (SDK's own Firebase for Remote Config)
export 'src/firebase/sdk_firebase_initializer.dart';
export 'src/firebase/sdk_firebase_config.dart';
export 'src/firebase/sdk_firebase_options.dart' show SdkFirebaseOptions;

export 'src/version.dart';
