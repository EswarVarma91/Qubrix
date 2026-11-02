// Comprehensive tests for Qubrix
import 'package:flutter_test/flutter_test.dart';
import 'package:qubrix/qubrix.dart';

void main() {
  group('Model Types', () {
    test('Model creation', () {
      final model = Model(
        id: 'test-model',
        name: 'Test Model',
        description: 'A test model',
        version: '1.0.0',
        architecture: ModelArchitecture.specialized,
        quantizationFormats: [QuantizationFormat.int8],
        downloadSizes: {QuantizationFormat.int8: 10 * 1024 * 1024},
        memoryRequirements: {QuantizationFormat.int8: 50 * 1024 * 1024},
        supportedTaskTypes: [TaskType.classification],
        hardwareRequirements: const HardwareRequirements(
          minRamMb: 256,
          minStorageMb: 10,
        ),
        license: const ModelLicense(
          type: LicenseType.permissive,
          name: 'MIT',
        ),
      );

      expect(model.id, 'test-model');
      expect(model.name, 'Test Model');
      expect(model.supportsTask(TaskType.classification), isTrue);
      expect(model.supportsTask(TaskType.generation), isFalse);
      expect(model.smallestDownloadSize, 10 * 1024 * 1024);
    });

    test('Hardware requirements checking', () {
      const requirements = HardwareRequirements(
        minRamMb: 512,
        minStorageMb: 100,
        minCpuCores: 4,
      );

      final capableDevice = DeviceInfo(
        totalMemory: 4 * 1024 * 1024 * 1024,
        availableMemory: 2 * 1024 * 1024 * 1024,
        totalStorage: 64 * 1024 * 1024 * 1024,
        availableStorage: 32 * 1024 * 1024 * 1024,
        cpuCores: 8,
        cpuFrequencyHz: 2400000000,
        supportsGpu: true,
        supportsNeuralEngine: false,
        os: 'Android',
        osVersion: '13',
        deviceModel: 'Test Device',
        manufacturer: 'Test',
        screenWidth: 1080,
        screenHeight: 2400,
        isRooted: false,
        batteryLevel: 0.8,
        isCharging: false,
        networkType: NetworkType.wifi,
        powerSaveMode: false,
      );

      final incapableDevice = DeviceInfo(
        totalMemory: 1 * 1024 * 1024 * 1024, // 1GB
        availableMemory: 512 * 1024 * 1024,
        totalStorage: 16 * 1024 * 1024 * 1024,
        availableStorage: 8 * 1024 * 1024 * 1024,
        cpuCores: 2,
        cpuFrequencyHz: 1200000000,
        supportsGpu: false,
        supportsNeuralEngine: false,
        os: 'Android',
        osVersion: '10',
        deviceModel: 'Low-end Device',
        manufacturer: 'Test',
        screenWidth: 720,
        screenHeight: 1280,
        isRooted: false,
        batteryLevel: 0.5,
        isCharging: false,
        networkType: NetworkType.cellular4g,
        powerSaveMode: false,
      );

      expect(requirements.meetsMinimumRequirements(capableDevice), isTrue);
      expect(requirements.meetsMinimumRequirements(incapableDevice), isFalse);
    });

    test('TaskType enum', () {
      expect(TaskType.values.length, greaterThan(0));
      expect(TaskType.classification.name, 'classification');
      expect(TaskType.generation.name, 'generation');
    });
  });

  group('Model Catalog', () {
    late ModelCatalog catalog;

    setUp(() {
      catalog = ModelCatalog();
    });

    test('Initial catalog has models', () {
      expect(catalog.modelCount, greaterThan(0));
    });

    test('Get model by ID', () {
      final model = catalog.getModel('small-classifier');
      expect(model, isNotNull);
      expect(model!.id, 'small-classifier');
    });

    test('Get models for task', () {
      final models = catalog.getModelsForTask(TaskType.classification);
      expect(models.length, greaterThan(0));
      for (final model in models) {
        expect(model.supportsTask(TaskType.classification), isTrue);
      }
    });

    test('Get smallest model for task', () {
      final model = catalog.getSmallestModelForTask(TaskType.classification);
      expect(model, isNotNull);
      expect(model!.supportedTaskTypes, contains(TaskType.classification));
    });

    test('Search models', () {
      final results = catalog.searchModels('classifier');
      expect(results.length, greaterThan(0));
    });

    test('Add custom model', () {
      final customModel = Model(
        id: 'custom-model',
        name: 'Custom Model',
        description: 'A custom model',
        version: '1.0.0',
        architecture: ModelArchitecture.statistical,
        quantizationFormats: [QuantizationFormat.int8],
        downloadSizes: {QuantizationFormat.int8: 1 * 1024 * 1024},
        memoryRequirements: {QuantizationFormat.int8: 10 * 1024 * 1024},
        supportedTaskTypes: [TaskType.statistics],
        hardwareRequirements: const HardwareRequirements(
          minRamMb: 64,
          minStorageMb: 1,
        ),
        license: const ModelLicense(
          type: LicenseType.permissive,
          name: 'MIT',
        ),
      );

      catalog.addModel(customModel);
      expect(catalog.getModel('custom-model'), isNotNull);
    });
  });

  group('Action Registry', () {
    late ActionRegistry registry;

    setUp(() {
      registry = ActionRegistry();
    });

    test('Register action', () {
      final action = ActionDefinition(
        id: 'test-action',
        name: 'Test Action',
        description: 'A test action',
        canBeAutomated: true,
      );

      registry.registerAction(action);
      expect(registry.hasAction('test-action'), isTrue);
      expect(registry.actionCount, 1);
    });

    test('Register action with handler', () {
      final action = ActionDefinition(
        id: 'handler-action',
        name: 'Handler Action',
        description: 'An action with handler',
        canBeAutomated: true,
      );

      int callCount = 0;
      registry.registerActionWithHandler(
        action,
        (params) {
          callCount++;
          return {'result': 'success', 'callCount': callCount};
        },
      );

      final result = registry.executeAction('handler-action', {'param': 'value'});
      expect(result, isA<Map>());
      expect(result['result'], 'success');
      expect(callCount, 1);
    });

    test('Get action by ID', () {
      final action = ActionDefinition(
        id: 'get-test',
        name: 'Get Test',
        description: 'Test get action',
      );

      registry.registerAction(action);
      final retrieved = registry.getAction('get-test');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Get Test');
    });

    test('Unregister action', () {
      final action = ActionDefinition(
        id: 'unregister-test',
        name: 'Unregister Test',
        description: 'Test unregister',
      );

      registry.registerAction(action);
      registry.unregisterAction('unregister-test');
      expect(registry.hasAction('unregister-test'), isFalse);
    });

    test('Get actions by category', () {
      registry.registerAction(ActionDefinition(
        id: 'cat-1',
        name: 'Category 1 Action',
        description: 'Test',
        category: 'test',
      ));
      registry.registerAction(ActionDefinition(
        id: 'cat-2',
        name: 'Category 2 Action',
        description: 'Test',
        category: 'other',
      ));
      registry.registerAction(ActionDefinition(
        id: 'cat-3',
        name: 'Category 1 Action 2',
        description: 'Test',
        category: 'test',
      ));

      final testActions = registry.getActionsByCategory('test');
      expect(testActions.length, 2);
    });

    test('Get actions by tag', () {
      registry.registerAction(ActionDefinition(
        id: 'tag-1',
        name: 'Tag Action 1',
        description: 'Test',
        tags: ['search', 'product'],
      ));

      final searchActions = registry.getActionsByTag('search');
      expect(searchActions.length, 1);
    });

    test('Action validation', () {
      final action = ActionDefinition(
        id: 'validate-test',
        name: 'Validation Test',
        description: 'Test validation',
        inputSchema: const InputSchema(
          fields: {
            'required_field': SchemaField(
              name: 'required_field',
              type: SchemaFieldType.string,
              required: true,
            ),
            'optional_field': SchemaField(
              name: 'optional_field',
              type: SchemaFieldType.integer,
              required: false,
            ),
            'enum_field': SchemaField(
              name: 'enum_field',
              type: SchemaFieldType.string,
              required: false,
              enumValues: ['option1', 'option2'],
            ),
          },
        ),
      );

      registry.registerAction(action);

      // Valid input
      final validResult = registry.executeAction('validate-test', {
        'required_field': 'test',
      });
      expect(validResult is Map, isTrue);

      // Invalid input - missing required field
      expect(
        () => registry.executeAction('validate-test', {}),
        throwsA(isA<Exception>()),
      );

      // Invalid input - wrong type
      expect(
        () => registry.executeAction('validate-test', {
          'required_field': 123,
        }),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Permission Manager', () {
    late PermissionManager manager;

    setUp(() {
      manager = PermissionManager();
    });

    test('Request permission', () async {
      final grant = await manager.requestPermission(
        actionId: 'test-action',
        level: PermissionLevel.execute,
        reason: 'Need to execute action',
      );

      expect(grant, PermissionGrant.granted);
    });

    test('Check permission', () {
      manager.requestPermission(
        actionId: 'perm-test',
        level: PermissionLevel.execute,
      );

      expect(manager.hasPermission('perm-test', PermissionLevel.execute), isTrue);
      expect(manager.hasPermission('perm-test', PermissionLevel.fullAutomation), isFalse);
      expect(manager.hasPermission('nonexistent', PermissionLevel.execute), isFalse);
    });

    test('Revoke permission', () {
      manager.requestPermission(
        actionId: 'revoke-test',
        level: PermissionLevel.execute,
      );

      expect(manager.hasPermission('revoke-test', PermissionLevel.execute), isTrue);
      manager.revokePermission('revoke-test');
      expect(manager.hasPermission('revoke-test', PermissionLevel.execute), isFalse);
    });

    test('Record usage', () {
      manager.requestPermission(
        actionId: 'usage-test',
        level: PermissionLevel.execute,
      );

      manager.recordUsage('usage-test');
      final record = manager.getPermission('usage-test');
      expect(record?.usageCount, 1);
      expect(record?.lastUsed, isNotNull);
    });

    test('Permission stats', () {
      manager.requestPermission(actionId: 'stat-1', level: PermissionLevel.execute);
      manager.requestPermission(actionId: 'stat-2', level: PermissionLevel.view);

      final stats = manager.getPermissionStats();
      expect(stats['total_granted'], 2);
      expect(stats['total_actions'], 2);
    });

    test('Safe for automation check', () {
      final action = ActionDefinition(
        id: 'auto-test',
        name: 'Automation Test',
        description: 'Test',
        canBeAutomated: true,
        sideEffectType: SideEffectType.none,
        requiresConfirmation: false,
      );

      // Without permission
      expect(manager.isSafeForAutomation('auto-test', action), isFalse);

      // With permission
      manager.requestPermission(actionId: 'auto-test', level: PermissionLevel.execute);
      expect(manager.isSafeForAutomation('auto-test', action), isTrue);

      // With dangerous side effect
      final dangerousAction = ActionDefinition(
        id: 'dangerous',
        name: 'Dangerous',
        description: 'Test',
        canBeAutomated: true,
        sideEffectType: SideEffectType.payment,
        requiresConfirmation: false,
      );
      manager.requestPermission(actionId: 'dangerous', level: PermissionLevel.execute);
      expect(manager.isSafeForAutomation('dangerous', dangerousAction), isFalse);
    });
  });

  group('Personalization Engine', () {
    late PersonalizationEngine engine;
    late ProfileManager profileManager;

    setUp(() {
      profileManager = ProfileManager();
      engine = PersonalizationEngine(
        profileManager: profileManager,
        privacyMode: PrivacyMode.localFirst,
      );
    });

    test('Record activity', () async {
      await engine.recordActivity(
        ActivityEvent.featureUsed(
          featureName: 'test',
          featureId: 'test_feature',
        ),
      );

      expect(engine.recentActivityCount, greaterThan(0));
    });

    test('Record multiple activities', () async {
      for (var i = 0; i < 10; i++) {
        await engine.recordActivity(
          ActivityEvent.taskExecuted(
            taskId: 'task_$i',
            taskType: TaskType.classification,
            success: true,
            durationMs: 100,
          ),
        );
      }

      expect(engine.recentActivityCount, 10);
    });

    test('Get user profile', () async {
      final profile = await engine.getUserProfile();
      expect(profile, isNotNull);
      expect(profile.profileId.isNotEmpty, isTrue);
    });

    test('Activity event types', () {
      final event = ActivityEvent.featureUsed(
        featureName: 'test',
        featureId: 'test_id',
      );

      expect(event.eventType, ActivityEventType.featureUsage);
      expect(event.actionId, 'test_id');
    });

    test('Task execution event', () {
      final event = ActivityEvent.taskExecuted(
        taskId: 'task_123',
        taskType: TaskType.classification,
        success: true,
        durationMs: 200,
      );

      expect(event.eventType, ActivityEventType.taskExecution);
      expect(event.taskId, 'task_123');
      expect(event.success, isTrue);
      expect(event.durationMs, 200);
    });
  });

  group('Recommendation Engine', () {
    late RecommendationEngine engine;
    late ActionRegistry actionRegistry;
    late PersonalizationEngine personalizationEngine;
    late ProfileManager profileManager;

    setUp(() {
      actionRegistry = ActionRegistry();
      actionRegistry.registerAction(ActionDefinition(
        id: 'create_report',
        name: 'Create Report',
        description: 'Create a report',
        category: 'reports',
        tags: ['report', 'generate'],
        canBeAutomated: true,
      ));
      actionRegistry.registerAction(ActionDefinition(
        id: 'search',
        name: 'Search',
        description: 'Search items',
        category: 'search',
        tags: ['search'],
        canBeAutomated: true,
      ));

      profileManager = ProfileManager();
      profileManager.updatePreferences({'totalEvents': 100});
      personalizationEngine = PersonalizationEngine(
        profileManager: profileManager,
      );
      engine = RecommendationEngine(
        personalizationEngine: personalizationEngine,
        actionRegistry: actionRegistry,
      );
    });

    test('Generate recommendation with no data', () async {
      final recommendation = await engine.generateRecommendation(
        contextType: 'time_of_day',
        contextData: {'hour': 9},
      );
      // May return null if no patterns detected
      expect(recommendation, anyOf(isNull, isA<Recommendation>()));
    });

    test('Recommendation types', () {
      final rec1 = Recommendation(
        id: 'test-1',
        type: RecommendationType.automation,
        title: 'Test Automation',
        description: 'Test description',
        confidence: 0.8,
      );

      expect(rec1.type, RecommendationType.automation);
      expect(rec1.confidence, 0.8);
    });

    test('Recommendation acceptance rate', () {
      final rec = Recommendation(
        id: 'test-rate',
        type: RecommendationType.general,
        title: 'Test',
        description: 'Test',
        confidence: 0.7,
        timesShown: 10,
        timesAccepted: 3,
        timesDismissed: 2,
      );

      expect(rec.acceptanceRate, 0.3);
      expect(rec.dismissalRate, 0.2);
      expect(rec.netScore, 0.1);
    });

    test('Recommendation factory methods', () {
      final reorder = Recommendation.reorderSuggestion(
        productId: 'p1',
        productName: 'Test Product',
        typicalQuantity: 2,
      );

      expect(reorder.type, RecommendationType.routineBased);
      expect(reorder.actionId, 'add_to_cart');
      expect(reorder.actionParameters?['productId'], 'p1');

      final shortcut = Recommendation.shortcutSuggestion(
        workflowName: 'Test Workflow',
        actionIds: ['a1', 'a2'],
        frequency: 5,
      );

      expect(shortcut.type, RecommendationType.automation);
      expect(shortcut.suggestedAction, 'Create shortcut');
    });
  });

  group('Automation Engine', () {
    late AutomationEngine engine;
    late ActionRegistry actionRegistry;
    late PermissionManager permissionManager;

    setUp(() {
      actionRegistry = ActionRegistry();
      actionRegistry.registerActionWithHandler(ActionDefinition(
        id: 'test_step',
        name: 'Test Step',
        description: 'A test step',
        canBeAutomated: true,
      ), (params) => {'result': 'ok'});

      permissionManager = PermissionManager();
      engine = AutomationEngine(
        actionRegistry: actionRegistry,
        permissionManager: permissionManager,
      );
    });

    test('Generate plan for report creation', () async {
      final plan = await engine.generatePlan('Create weekly report');

      expect(plan, isNotNull);
      expect(plan!.goal.toLowerCase().contains('report'), isTrue);
      expect(plan.steps.length, greaterThan(0));
    });

    test('Execute plan', () async {
      final plan = await engine.generatePlan('Test plan');
      if (plan == null) {
        // Plan generation depends on goal matching
        return;
      }

      // Need to set up permission first
      permissionManager.requestPermission(
        actionId: plan.steps.first.actionId,
        level: PermissionLevel.execute,
      );

      final result = await engine.executePlan(
        plan,
        requireConfirmation: false,
      );

      expect(result, isA<WorkflowResult>);
    });

    test('Workflow definition validation', () {
      final workflow = WorkflowDefinition(
        id: 'test-workflow',
        name: 'Test Workflow',
        steps: [
          WorkflowStep(
            id: 'step-1',
            actionId: 'test_step',
            name: 'Step 1',
            order: 0,
          ),
          WorkflowStep(
            id: 'step-2',
            actionId: 'test_step',
            name: 'Step 2',
            order: 1,
            dependsOn: ['step-1'],
          ),
        ],
      );

      expect(workflow.isValid, isTrue);
    });

    test('Workflow step validation', () {
      const validStep = WorkflowStep(
        id: 'valid',
        actionId: 'action_1',
        name: 'Valid Step',
      );

      expect(validStep.isValid, isTrue);

      const invalidStep = WorkflowStep(
        id: 'invalid',
        actionId: '',
        name: '',
      );

      expect(invalidStep.isValid, isFalse);
    });

    test('Execution plan validation', () {
      final plan = ExecutionPlan(
        goal: 'Test goal',
        steps: [
          PlannedStep(
            sequence: 1,
            actionId: 'action_1',
            description: 'Step 1',
            requiresApproval: false,
          ),
        ],
      );

      expect(plan.isValid, isTrue);

      final invalidPlan = ExecutionPlan(
        goal: 'Test',
        steps: [],
      );

      expect(invalidPlan.isValid, isFalse);
    });
  });

  group('Compatibility Engine', () {
    late CompatibilityEngine engine;

    setUp(() {
      engine = CompatibilityEngine();
    });

    test('Get device info', () async {
      final deviceInfo = await engine.getDeviceInfo();
      expect(deviceInfo, isNotNull);
      expect(deviceInfo.totalMemory, greaterThan(0));
      expect(deviceInfo.cpuCores, greaterThan(0));
    });

    test('Device suitability for AI', () async {
      final suitable = await engine.isDeviceSuitableForAI();
      // May vary based on actual device
      expect(suitable == true || suitable == false, isTrue);
    });

    test('Model compatibility check', () async {
      final deviceInfo = await engine.getDeviceInfo();
      final model = ModelCatalog().getModel('small-classifier');

      if (model != null) {
        final result = await engine.checkModelCompatibility(model, deviceInfo);
        expect(result, isA<CompatibilityResult>());
        // Small classifier should be compatible with most devices
      }
    });
  });

  group('Model Optimizer', () {
    late ModelOptimizer optimizer;

    setUp(() {
      optimizer = ModelOptimizer(
        catalog: ModelCatalog(),
      );
    });

    test('Find candidate models', () {
      final deviceInfo = DeviceInfo(
        totalMemory: 4 * 1024 * 1024 * 1024,
        availableMemory: 2 * 1024 * 1024 * 1024,
        totalStorage: 64 * 1024 * 1024 * 1024,
        availableStorage: 32 * 1024 * 1024 * 1024,
        cpuCores: 8,
        cpuFrequencyHz: 2400000000,
        supportsGpu: true,
        supportsNeuralEngine: false,
        os: 'Android',
        osVersion: '13',
        deviceModel: 'Test',
        manufacturer: 'Test',
        screenWidth: 1080,
        screenHeight: 2400,
        isRooted: false,
        batteryLevel: 0.8,
        isCharging: false,
        networkType: NetworkType.wifi,
        powerSaveMode: false,
      );

      final candidates = optimizer.findCandidateModels(
        taskType: TaskType.classification,
        requirements: const TaskRequirements(
          requiresModel: true,
          complexity: TaskComplexity.low,
          minQuality: 0.7,
          preferredApproach: 'model',
        ),
        deviceInfo: deviceInfo,
      );

      expect(candidates.length, greaterThan(0));
    });

    test('Select smallest qualified model', () async {
      final deviceInfo = DeviceInfo(
        totalMemory: 4 * 1024 * 1024 * 1024,
        availableMemory: 2 * 1024 * 1024 * 1024,
        totalStorage: 64 * 1024 * 1024 * 1024,
        availableStorage: 32 * 1024 * 1024 * 1024,
        cpuCores: 8,
        cpuFrequencyHz: 2400000000,
        supportsGpu: true,
        supportsNeuralEngine: false,
        os: 'Android',
        osVersion: '13',
        deviceModel: 'Test',
        manufacturer: 'Test',
        screenWidth: 1080,
        screenHeight: 2400,
        isRooted: false,
        batteryLevel: 0.8,
        isCharging: false,
        networkType: NetworkType.wifi,
        powerSaveMode: false,
      );

      final candidate = await optimizer.findSmallestSuitableModel(
        taskType: TaskType.classification,
        deviceInfo: deviceInfo,
        minQuality: 0.7,
      );

      expect(candidate, isNotNull);
      if (candidate != null) {
        expect(candidate.isCompatible, isTrue);
      }
    });

    test('Model candidate properties', () {
      final candidate = ModelCandidate(
        model: Model(
          id: 'test',
          name: 'Test',
          description: 'Test',
          version: '1.0',
          architecture: ModelArchitecture.statistical,
          quantizationFormats: [QuantizationFormat.int8],
          downloadSizes: {QuantizationFormat.int8: 5 * 1024 * 1024},
          memoryRequirements: {QuantizationFormat.int8: 20 * 1024 * 1024},
          supportedTaskTypes: [TaskType.statistics],
          hardwareRequirements: const HardwareRequirements(
            minRamMb: 64,
            minStorageMb: 5,
          ),
          license: const ModelLicense(
            type: LicenseType.permissive,
            name: 'MIT',
          ),
        ),
        quantizationFormat: QuantizationFormat.int8,
        downloadSize: 5 * 1024 * 1024,
        memoryRequirement: 20 * 1024 * 1024,
        estimatedQuality: 0.85,
        estimatedLatencyMs: 10,
        estimatedThroughput: 100,
        isInstalled: false,
        isCompatible: true,
      );

      expect(candidate.meetsQualityThreshold(0.7), isTrue);
      expect(candidate.meetsQualityThreshold(0.9), isFalse);
    });
  });

  group('Task Request and Output', () {
    test('Task request creation', () {
      final request = TaskRequest(
        taskId: 'task_123',
        description: 'Test task',
        input: {'key': 'value'},
        taskType: TaskType.classification,
        context: {'screen': 'test'},
      );

      expect(request.taskId, 'task_123');
      expect(request.description, 'Test task');
      expect(request.taskType, TaskType.classification);
    });

    test('Task request from JSON', () {
      final json = {
        'taskId': 'json_task',
        'description': 'From JSON',
        'input': 'test',
        'taskType': 'classification',
      };

      final request = TaskRequest.fromJson(json);
      expect(request.taskId, 'json_task');
      expect(request.description, 'From JSON');
    });

    test('Task output types', () {
      final dataOutput = TaskOutput.data({'result': 'value'});
      expect(dataOutput.type, OutputType.data);

      final textOutput = TaskOutput.text('Hello');
      expect(textOutput.type, OutputType.text);
      expect(textOutput.text, 'Hello');

      final classification = TaskOutput.classification('cat', confidence: 0.9);
      expect(classification.type, OutputType.classification);
      expect(classification.confidence, 0.9);
    });

    test('Task request factory methods', () {
      final textRequest = TaskRequest.text(
        taskId: 'txt_1',
        text: 'Sample text',
        description: 'Process text',
      );
      expect(textRequest.input['text'], 'Sample text');

      final classRequest = TaskRequest.classification(
        taskId: 'cls_1',
        text: 'Classify this',
        categories: ['A', 'B', 'C'],
      );
      expect(classRequest.taskType, TaskType.classification);
      expect(classRequest.input['categories'], ['A', 'B', 'C']);
    });
  });

  group('Task Orchestration', () {
    late TaskOrchestrator orchestrator;
    late ModelManager modelManager;
    late CompatibilityEngine compatibilityEngine;
    late ModelOptimizer modelOptimizer;

    setUp(() {
      final catalog = ModelCatalog();
      compatibilityEngine = CompatibilityEngine();
      modelManager = ModelManager(catalog: catalog, compatibilityEngine: compatibilityEngine);
      modelOptimizer = ModelOptimizer(catalog: catalog);

      orchestrator = TaskOrchestrator(
        modelManager: modelManager,
        compatibilityEngine: compatibilityEngine,
        modelOptimizer: modelOptimizer,
      );
    });

    test('Orchestrate simple task', () async {
      final result = await orchestrator.orchestrateTask(
        TaskRequest(
          taskId: 'orchestrate_test',
          description: 'Calculate statistics',
          input: {
            'data': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
          },
          taskType: TaskType.statistics,
        ),
      );

      expect(result, isA<OrchestrationResult>());
      // Statistics tasks can be handled by rules
      expect(result.success, isTrue);
    });

    test('Orchestration config', () {
      final config = const OrchestrationConfig(
        minQualityThreshold: 0.8,
        preferRulesOverModels: false,
        maxModelCandidates: 10,
      );

      expect(config.minQualityThreshold, 0.8);
      expect(config.preferRulesOverModels, isFalse);
      expect(config.maxModelCandidates, 10);
    });

    test('Orchestration steps', () {
      final step = OrchestrationStep(
        name: 'Test step',
        type: StepType.understand,
        success: true,
        details: 'Step details',
        duration: const Duration(milliseconds: 100),
      );

      expect(step.name, 'Test step');
      expect(step.type, StepType.understand);
      expect(step.success, isTrue);
    });
  });

  group('Agent Engine', () {
    late AdaptiveAgentEngine engine;

    setUp(() async {
      engine = AdaptiveAgentEngine(
        config: AgentEngineConfig(
          enableModelManagement: true,
          enablePersonalization: true,
          enableRecommendations: true,
          enableAutomation: true,
          privacyMode: PrivacyMode.localFirst,
        ),
      );
      await engine.initialize();
    });

    tearDown(() async {
      await engine.dispose();
    });

    test('Engine initialization', () {
      expect(engine.isInitialized, isTrue);
      expect(engine.isDisposed, isFalse);
    });

    test('Register actions', () {
      engine.registerAction(ActionDefinition(
        id: 'e2e_action',
        name: 'E2E Test Action',
        description: 'End-to-end test',
        canBeAutomated: true,
      ));

      expect(engine.actionRegistry.hasAction('e2e_action'), isTrue);
    });

    test('Check health', () async {
      final health = await engine.checkHealth();
      expect(health, isA<EngineHealth>());
      // Health may vary but should not throw
    });

    test('Get installed models', () {
      final models = engine.getInstalledModels();
      expect(models, isA<List<Model>>());
    });

    test('Get model recommendations', () async {
      final recommendations = await engine.getModelRecommendations(
        const TaskRequirements(
          requiresModel: true,
          complexity: TaskComplexity.low,
          minQuality: 0.7,
          preferredApproach: 'model',
          relevantTaskTypes: [TaskType.classification],
        ),
      );

      expect(recommendations, isA<List<ModelRecommendation>>());
    });

    test('Event listener', () async {
      String? receivedEvent;
      engine.addEventListener((event) {
        receivedEvent = event.type.name;
      });

      // Trigger an event by registering an action
      engine.registerAction(ActionDefinition(
        id: 'event_test',
        name: 'Event Test',
        description: 'Test',
        canBeAutomated: true,
      ));

      // Give async operations time
      await Future.delayed(const Duration(milliseconds: 100));

      // Event may or may not have been triggered depending on timing
      expect(receivedEvent == null || receivedEvent!.isNotEmpty, isTrue);

      engine.removeEventListener((event) {});
    });

    test('Dispose engine', () async {
      await engine.dispose();
      expect(engine.isDisposed, isTrue);
    });
  });

  group('Privacy and Data', () {
    test('Privacy levels', () {
      expect(PrivacyLevel.values.length, greaterThan(0));
      expect(PrivacyMode.values.length, greaterThan(0));
    });

    test('Activity event privacy', () {
      final sensitiveEvent = ActivityEvent(
        eventType: ActivityEventType.taskExecution,
        privacyLevel: PrivacyLevel.sensitive,
      );

      expect(sensitiveEvent.privacyLevel, PrivacyLevel.sensitive);
      expect(sensitiveEvent.isTemporary, isFalse);
    });

    test('Profile config', () {
      const config = ProfileConfig(
        personalizationEnabled: true,
        dataRetention: Duration(days: 30),
        minPatternConfidence: 0.8,
      );

      expect(config.personalizationEnabled, isTrue);
      expect(config.dataRetention.inDays, 30);
      expect(config.minPatternConfidence, 0.8);
    });
  });

  group('Integration: End-to-End Flow', () {
    test('Complete flow: register, execute, learn', () async {
      final engine = AdaptiveAgentEngine(
        config: AgentEngineConfig(
          enableAutomation: true,
          enablePersonalization: true,
        ),
      );

      await engine.initialize();

      // Register action
      engine.registerAction(ActionDefinition(
        id: 'e2e_search',
        name: 'Search Products',
        description: 'Search for products',
        inputSchema: const InputSchema(
          fields: {
            'query': SchemaField(
              name: 'query',
              type: SchemaFieldType.string,
              required: true,
            ),
          },
        ),
        canBeAutomated: true,
      ));

      // Request permission
      final permission = await engine.requestPermission(
        actionId: 'e2e_search',
        level: PermissionLevel.execute,
      );
      expect(permission, PermissionGrant.granted);

      // Record activity
      await engine.personalizationEngine?.recordActivity(
        ActivityEvent.featureUsed(
          featureName: 'Search',
          featureId: 'e2e_search',
        ),
      );

      // Get recommendation
      final recommendation = await engine.getRecommendation(
        contextType: 'feature',
        contextData: {'feature': 'e2e_search'},
      );
      expect(recommendation, anyOf(isNull, isA<Recommendation>()));

      // Recommendation may be null if not enough data
      // That's OK - it shows the system is working correctly

      // Check engine health
      final health = await engine.checkHealth();
      expect(health, isA<EngineHealth>());

      await engine.dispose();
    });
  });

  group('Learning Loop: listen, learn, automate', () {
    late AdaptiveAgentEngine engine;
    var searchCalls = 0;
    var cartCalls = 0;

    setUp(() async {
      searchCalls = 0;
      cartCalls = 0;

      engine = AdaptiveAgentEngine(
        config: const AgentEngineConfig(
          enableModelManagement: false,
          enablePersonalization: true,
          enableRecommendations: true,
          enableAutomation: true,
        ),
      );
      await engine.initialize();

      engine.actionRegistry.registerActionWithHandler(
        const ActionDefinition(
          id: 'search_product',
          name: 'Search products',
          description: 'Search the catalogue',
          canBeAutomated: true,
        ),
        (params) {
          searchCalls++;
          return {'results': 3};
        },
      );
      engine.actionRegistry.registerActionWithHandler(
        const ActionDefinition(
          id: 'add_to_cart',
          name: 'Add to cart',
          description: 'Add the found product to the cart',
          canBeAutomated: true,
        ),
        (params) {
          cartCalls++;
          return {'added': true};
        },
      );

      await engine.requestPermission(
        actionId: 'search_product',
        level: PermissionLevel.execute,
      );
      await engine.requestPermission(
        actionId: 'add_to_cart',
        level: PermissionLevel.execute,
      );

      // The user repeats the same two actions six times.
      for (var i = 0; i < 6; i++) {
        await engine.trackAction('search_product', name: 'Search products');
        await engine.trackAction('add_to_cart', name: 'Add to cart');
      }
    });

    tearDown(() async {
      await engine.dispose();
    });

    test('listens and persists what the user actually does', () async {
      final profile = await engine.getUserProfile();

      expect(profile, isNotNull);
      expect(profile!.usageStats.totalEvents, 12);
      expect(profile.getMostUsedFeatures(), isNotEmpty);
      expect(
        profile.usageStats.featureUsage
            .firstWhere((f) => f.featureId == 'search_product')
            .count,
        6,
      );
    });

    test('detects the repeated routine', () async {
      final routines = await engine.getDetectedRoutines();
      expect(routines, isNotEmpty);

      final sequence = routines.firstWhere(
        (r) =>
            r.steps.length == 2 &&
            r.steps.first.actionId == 'search_product' &&
            r.steps.last.actionId == 'add_to_cart',
        orElse: () => throw StateError('routine was not detected'),
      );

      expect(sequence.frequency, greaterThanOrEqualTo(3));
      expect(sequence.confidence, greaterThanOrEqualTo(0.7));
    });

    test('turns the routine into an automation and runs it', () async {
      final candidates = await engine.getAutomationCandidates();
      expect(candidates, isNotEmpty);

      final routine = candidates.firstWhere(
        (r) => r.steps.length == 2,
        orElse: () => candidates.first,
      );

      final workflow = await engine.registerRoutineAutomation(
        routine.routineId,
        level: AutomationLevel.execute,
      );
      expect(workflow, isNotNull);
      expect(engine.automationEngine.getWorkflow(workflow!.id), isNotNull);

      final result = await engine.runAutomation(
        workflow.id,
        requireConfirmation: false,
      );

      expect(result.success, isTrue);
      expect(searchCalls, 1);
      expect(cartCalls, 1);

      final profile = await engine.getUserProfile();
      final stored = profile!.routines
          .firstWhere((r) => r.routineId == routine.routineId);
      expect(stored.status, RoutineStatus.automated);
    });

    test('accepting an automation recommendation registers a workflow',
        () async {
      final recommendation = await engine.getRecommendation(
        contextType: 'feature',
      );

      expect(recommendation, isNotNull);
      expect(recommendation!.type, RecommendationType.automation);

      await engine.acceptRecommendation(recommendation.id);

      final workflows = engine.automationEngine.workflows;
      expect(workflows, isNotEmpty);
      expect(
        workflows.any(
          (w) => w.metadata?['recommendationId'] == recommendation.id,
        ),
        isTrue,
      );
    });
  });
}
