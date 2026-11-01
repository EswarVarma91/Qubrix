/// Action Registry
///
/// Registers application actions that the automation engine can use.
/// Developer-defined operations that applications expose.

import 'package:flutter/foundation.dart';

/// A definition of an application action
@immutable
class ActionDefinition {
  /// Unique action identifier
  final String id;

  /// Human-readable name
  final String name;

  /// Description of what the action does
  final String description;

  /// Category for grouping actions
  final String? category;

  /// Tags for search/filtering
  final List<String> tags;

  /// Input schema for the action
  final InputSchema? inputSchema;

  /// Required permissions for this action
  final List<PermissionLevel> requiredPermissions;

  /// Whether this action has side effects
  final bool hasSideEffects;

  /// Side effect type (if applicable)
  final SideEffectType? sideEffectType;

  /// Whether this action is reversible
  final bool isReversible;

  /// Whether explicit confirmation is required
  final bool requiresConfirmation;

  /// Confirmation message to show
  final String? confirmationMessage;

  /// Default parameters for the action
  final Map<String, dynamic>? defaultParameters;

  /// Context triggers that can invoke this action
  final Map<String, dynamic>? contextTriggers;

  /// Whether this action can be automated
  final bool canBeAutomated;

  /// Whether this action is currently enabled
  final bool isEnabled;

  /// Execution timeout
  final Duration? timeout;

  /// Idempotency key field (if applicable)
  final String? idempotencyKeyField;

  const ActionDefinition({
    required this.id,
    required this.name,
    required this.description,
    this.category,
    this.tags = const [],
    this.inputSchema,
    this.requiredPermissions = const [PermissionLevel.execute],
    this.hasSideEffects = false,
    this.sideEffectType,
    this.isReversible = false,
    this.requiresConfirmation = false,
    this.confirmationMessage,
    this.defaultParameters,
    this.contextTriggers,
    this.canBeAutomated = true,
    this.isEnabled = true,
    this.timeout,
    this.idempotencyKeyField,
  });

  /// Check if this action requires strong confirmation
  bool get requiresStrongConfirmation {
    return requiresConfirmation ||
        hasSideEffects ||
        sideEffectType == SideEffectType.payment ||
        sideEffectType == SideEffectType.dataDeletion ||
        sideEffectType == SideEffectType.externalCommunication;
  }

  /// Merge with another definition (for updates)
  ActionDefinition copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    List<String>? tags,
    InputSchema? inputSchema,
    List<PermissionLevel>? requiredPermissions,
    bool? hasSideEffects,
    SideEffectType? sideEffectType,
    bool? isReversible,
    bool? requiresConfirmation,
    String? confirmationMessage,
    Map<String, dynamic>? defaultParameters,
    Map<String, dynamic>? contextTriggers,
    bool? canBeAutomated,
    bool? isEnabled,
    Duration? timeout,
    String? idempotencyKeyField,
  }) {
    return ActionDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      inputSchema: inputSchema ?? this.inputSchema,
      requiredPermissions: requiredPermissions ?? this.requiredPermissions,
      hasSideEffects: hasSideEffects ?? this.hasSideEffects,
      sideEffectType: sideEffectType ?? this.sideEffectType,
      isReversible: isReversible ?? this.isReversible,
      requiresConfirmation: requiresConfirmation ?? this.requiresConfirmation,
      confirmationMessage:
          confirmationMessage ?? this.confirmationMessage,
      defaultParameters: defaultParameters ?? this.defaultParameters,
      contextTriggers: contextTriggers ?? this.contextTriggers,
      canBeAutomated: canBeAutomated ?? this.canBeAutomated,
      isEnabled: isEnabled ?? this.isEnabled,
      timeout: timeout ?? this.timeout,
      idempotencyKeyField:
          idempotencyKeyField ?? this.idempotencyKeyField,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category,
        'tags': tags,
        'inputSchema': inputSchema?.toJson(),
        'requiredPermissions': requiredPermissions.map((p) => p.name).toList(),
        'hasSideEffects': hasSideEffects,
        'sideEffectType': sideEffectType?.name,
        'isReversible': isReversible,
        'requiresConfirmation': requiresConfirmation,
        'confirmationMessage': confirmationMessage,
        'defaultParameters': defaultParameters,
        'contextTriggers': contextTriggers,
        'canBeAutomated': canBeAutomated,
        'isEnabled': isEnabled,
        'timeout': timeout?.inMilliseconds,
        'idempotencyKeyField': idempotencyKeyField,
      };

  factory ActionDefinition.fromJson(Map<String, dynamic> json) {
    return ActionDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String?,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((t) => t as String)
              .toList() ??
          [],
      inputSchema: json['inputSchema'] != null
          ? InputSchema.fromJson(json['inputSchema'] as Map<String, dynamic>)
          : null,
      requiredPermissions: (json['requiredPermissions'] as List<dynamic>?)
              ?.map((p) =>
                  PermissionLevel.values.firstWhere(
                    (e) => e.name == p,
                    orElse: () => PermissionLevel.execute,
                  ))
              .toList() ??
          [PermissionLevel.execute],
      hasSideEffects: json['hasSideEffects'] as bool? ?? false,
      sideEffectType: json['sideEffectType'] != null
          ? SideEffectType.values.firstWhere(
              (e) => e.name == json['sideEffectType'],
              orElse: () => SideEffectType.none,
            )
          : null,
      isReversible: json['isReversible'] as bool? ?? false,
      requiresConfirmation: json['requiresConfirmation'] as bool? ?? false,
      confirmationMessage: json['confirmationMessage'] as String?,
      defaultParameters:
          json['defaultParameters'] as Map<String, dynamic>?,
      contextTriggers: json['contextTriggers'] as Map<String, dynamic>?,
      canBeAutomated: json['canBeAutomated'] as bool? ?? true,
      isEnabled: json['isEnabled'] as bool? ?? true,
      timeout: json['timeout'] != null
          ? Duration(milliseconds: json['timeout'] as int)
          : null,
      idempotencyKeyField: json['idempotencyKeyField'] as String?,
    );
  }

  @override
  String toString() => 'ActionDefinition($name)';
}

/// Input schema for an action
@immutable
class InputSchema {
  final Map<String, SchemaField> fields;
  final String? example;

  const InputSchema({
    this.fields = const {},
    this.example,
  });

  /// Validate input against schema
  SchemaValidationResult validate(Map<String, dynamic> input) {
    final errors = <String>[];
    final warnings = <String>[];

    for (final entry in fields.entries) {
      final fieldName = entry.key;
      final field = entry.value;
      final value = input[fieldName];

      if (field.required && (value == null || value == '')) {
        if (field.defaultValue != null) continue; // Has default
        errors.add('Missing required field: $fieldName');
        continue;
      }

      if (value != null) {
        // Type check
        if (!field.isTypeValid(value)) {
          errors.add('Invalid type for $fieldName: expected ${field.type}');
          continue;
        }

        // Enum validation
        if (field.enumValues != null && field.enumValues!.isNotEmpty) {
          if (!field.enumValues!.contains(value)) {
            errors.add('$fieldName must be one of ${field.enumValues}');
          }
        }

        // Range validation
        if (field.min != null && field.type == SchemaFieldType.number) {
          if ((value as num) < field.min!) {
            errors.add('$fieldName must be >= ${field.min}');
          }
        }
        if (field.max != null && field.type == SchemaFieldType.number) {
          if ((value as num) > field.max!) {
            errors.add('$fieldName must be <= ${field.max}');
          }
        }

        // String length validation
        if (field.type == SchemaFieldType.string) {
          final strValue = value as String;
          if (field.minLength != null && strValue.length < field.minLength!) {
            errors.add('$fieldName must be at least ${field.minLength} characters');
          }
          if (field.maxLength != null && strValue.length > field.maxLength!) {
            errors.add('$fieldName must be at most ${field.maxLength} characters');
          }
        }
      }
    }

    return SchemaValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  Map<String, dynamic> toJson() => {
        'fields': fields.map((k, v) => MapEntry(k, v.toJson())),
        'example': example,
      };

  factory InputSchema.fromJson(Map<String, dynamic> json) {
    return InputSchema(
      fields: (json['fields'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(
                  k, SchemaField.fromJson(v as Map<String, dynamic>))) ??
          {},
      example: json['example'] as String?,
    );
  }
}

/// Field in an input schema
@immutable
class SchemaField {
  final String name;
  final String? title;
  final String? description;
  final SchemaFieldType type;
  final bool required;
  final dynamic defaultValue;
  final List<String>? enumValues;
  final num? min;
  final num? max;
  final int? minLength;
  final int? maxLength;
  final String? pattern;
  final String? format;

  const SchemaField({
    required this.name,
    this.title,
    this.description,
    required this.type,
    this.required = false,
    this.defaultValue,
    this.enumValues,
    this.min,
    this.max,
    this.minLength,
    this.maxLength,
    this.pattern,
    this.format,
  });

  bool isTypeValid(dynamic value) {
    switch (type) {
      case SchemaFieldType.string:
        return value is String;
      case SchemaFieldType.integer:
        return value is int;
      case SchemaFieldType.number:
        return value is num;
      case SchemaFieldType.boolean:
        return value is bool;
      case SchemaFieldType.list:
        return value is List;
      case SchemaFieldType.object:
        return value is Map;
      case SchemaFieldType.stringEnum:
        return value is String && (enumValues == null || enumValues!.contains(value));
    }
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'title': title,
        'description': description,
        'type': type.name,
        'required': required,
        'defaultValue': defaultValue,
        'enumValues': enumValues,
        'min': min,
        'max': max,
        'minLength': minLength,
        'maxLength': maxLength,
        'pattern': pattern,
        'format': format,
      };

  factory SchemaField.fromJson(Map<String, dynamic> json) {
    return SchemaField(
      name: json['name'] as String,
      title: json['title'] as String?,
      description: json['description'] as String?,
      type: SchemaFieldType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SchemaFieldType.string,
      ),
      required: json['required'] as bool? ?? false,
      defaultValue: json['defaultValue'],
      enumValues: (json['enumValues'] as List<dynamic>?)
          ?.map((v) => v as String)
          .toList(),
      min: json['min'] as num?,
      max: json['max'] as num?,
      minLength: json['minLength'] as int?,
      maxLength: json['maxLength'] as int?,
      pattern: json['pattern'] as String?,
      format: json['format'] as String?,
    );
  }
}

enum SchemaFieldType {
  string,
  integer,
  number,
  boolean,
  list,
  object,
  stringEnum,
}

class SchemaValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const SchemaValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });
}

/// Types of side effects
enum SideEffectType {
  /// No significant side effects
  none,

  /// Creates/modifies data
  dataModification,

  /// Deletes data
  dataDeletion,

  /// Involves payment
  payment,

  /// Sends external communication
  externalCommunication,

  /// Shares data externally
  dataSharing,

  /// Changes settings
  settingsChange,

  /// Performs device action
  deviceAction,
}

/// Permission levels for actions
enum PermissionLevel {
  /// View/read only
  view,

  /// Can suggest but not execute
  suggest,

  /// Can execute with user confirmation
  executeWithConfirmation,

  /// Can execute (for non-critical actions)
  execute,

  /// Full automation (for trusted routines)
  fullAutomation,
}

/// Action registry for managing registered actions
class ActionRegistry {
  final Map<String, ActionDefinition> _actions = {};
  final Map<String, Function(Map<String, dynamic>)> _handlers = {};

  /// Register an action
  void registerAction(ActionDefinition action) {
    if (action.isEnabled) {
      _actions[action.id] = action;
    }
  }

  /// Register an action with handler
  void registerActionWithHandler(
    ActionDefinition action,
    Function(Map<String, dynamic>) handler,
  ) {
    registerAction(action);
    _handlers[action.id] = handler;
  }

  /// Unregister an action
  void unregisterAction(String actionId) {
    _actions.remove(actionId);
    _handlers.remove(actionId);
  }

  /// Get an action by ID
  ActionDefinition? getAction(String actionId) {
    return _actions[actionId];
  }

  /// Get all registered actions
  List<ActionDefinition> get registeredActions {
    return _actions.values.toList();
  }

  /// Get actions by category
  List<ActionDefinition> getActionsByCategory(String category) {
    return _actions.values
        .where((a) => a.category == category)
        .toList();
  }

  /// Get actions by tag
  List<ActionDefinition> getActionsByTag(String tag) {
    return _actions.values
        .where((a) => a.tags.contains(tag))
        .toList();
  }

  /// Get enabled actions
  List<ActionDefinition> get enabledActions {
    return _actions.values.where((a) => a.isEnabled).toList();
  }

  /// Get actions that can be automated
  List<ActionDefinition> get automatableActions {
    return _actions.values.where((a) => a.canBeAutomated).toList();
  }

  /// Get actions that require confirmation
  List<ActionDefinition> get actionsRequiringConfirmation {
    return _actions.values.where((a) => a.requiresStrongConfirmation).toList();
  }

  /// Execute an action
  dynamic executeAction(
    String actionId,
    Map<String, dynamic> parameters, {
    String? idempotencyKey,
  }) {
    final action = _actions[actionId];
    if (action == null) {
      throw Exception('Action not registered: $actionId');
    }

    // Validate parameters
    if (action.inputSchema != null) {
      final validation = action.inputSchema!.validate(parameters);
      if (!validation.isValid) {
        throw Exception('Invalid parameters: ${validation.errors.join(', ')}');
      }
    }

    // Add idempotency key if applicable
    if (action.idempotencyKeyField != null && idempotencyKey != null) {
      parameters = Map<String, dynamic>.from(parameters);
      parameters[action.idempotencyKeyField!] = idempotencyKey;
    }

    final handler = _handlers[actionId];
    if (handler == null) {
      // Actions without a handler are declarative: echo the validated input.
      return Map<String, dynamic>.from(parameters);
    }

    return handler(parameters);
  }

  /// Check if action exists
  bool hasAction(String actionId) {
    return _actions.containsKey(actionId);
  }

  /// Check if action is enabled
  bool isActionEnabled(String actionId) {
    final action = _actions[actionId];
    return action?.isEnabled ?? false;
  }

  /// Get action count
  int get actionCount => _actions.length;

  /// Clear all actions
  void clear() {
    _actions.clear();
    _handlers.clear();
  }

  /// Get all action IDs
  List<String> get actionIds => _actions.keys.toList();
}
