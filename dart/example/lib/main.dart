// Example Flutter application demonstrating the AI SDK
import 'package:flutter/material.dart';
import 'package:ai_sdk/ai_sdk.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI SDK Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late AdaptiveAgentEngine _engine;
  bool _isInitialized = false;
  String _status = 'Not initialized';

  @override
  void initState() {
    super.initState();
    _initializeEngine();
  }

  Future<void> _initializeEngine() async {
    _engine = AdaptiveAgentEngine(
      config: AgentEngineConfig(
        enableModelManagement: true,
        enablePersonalization: true,
        enableRecommendations: true,
        enableAutomation: true,
        privacyMode: PrivacyMode.localFirst,
        minModelQuality: 0.7,
      ),
    );

    // Register sample actions for a shopping app
    _engine.registerActions([
      ActionDefinition(
        id: 'search_products',
        name: 'Search Products',
        description: 'Search for products by name or category',
        category: 'shopping',
        tags: ['search', 'products'],
        inputSchema: const InputSchema(
          fields: {
            'query': SchemaField(
              name: 'query',
              type: SchemaFieldType.string,
              required: true,
              description: 'Search query',
            ),
            'category': SchemaField(
              name: 'category',
              type: SchemaFieldType.string,
              required: false,
              description: 'Product category',
            ),
          },
        ),
        canBeAutomated: true,
      ),
      ActionDefinition(
        id: 'add_to_cart',
        name: 'Add to Cart',
        description: 'Add a product to the shopping cart',
        category: 'shopping',
        tags: ['cart', 'purchase'],
        inputSchema: const InputSchema(
          fields: {
            'product_id': SchemaField(
              name: 'product_id',
              type: SchemaFieldType.string,
              required: true,
            ),
            'quantity': SchemaField(
              name: 'quantity',
              type: SchemaFieldType.integer,
              required: false,
              defaultValue: 1,
              min: 1,
              max: 100,
            ),
          },
        ),
        hasSideEffects: true,
        sideEffectType: SideEffectType.payment,
        requiresConfirmation: true,
        confirmationMessage: 'Add this item to your cart?',
        canBeAutomated: true,
      ),
      ActionDefinition(
        id: 'create_report',
        name: 'Create Report',
        description: 'Generate a sales or analytics report',
        category: 'reports',
        tags: ['report', 'analytics', 'generate'],
        inputSchema: const InputSchema(
          fields: {
            'report_type': SchemaField(
              name: 'report_type',
              type: SchemaFieldType.string,
              required: true,
              enumValues: ['daily', 'weekly', 'monthly'],
            ),
            'date_range': SchemaField(
              name: 'date_range',
              type: SchemaFieldType.string,
              required: false,
              description: 'Date range for the report',
            ),
          },
        ),
        canBeAutomated: true,
      ),
      ActionDefinition(
        id: 'open_report',
        name: 'Open Report',
        description: 'Open a report for review',
        category: 'reports',
        tags: ['report', 'view'],
        inputSchema: const InputSchema(
          fields: {
            'report_id': SchemaField(
              name: 'report_id',
              type: SchemaFieldType.string,
              required: true,
            ),
          },
        ),
        canBeAutomated: true,
      ),
    ]);

    await _engine.initialize();
    setState(() {
      _isInitialized = true;
      _status = 'Engine initialized';
    });
  }

  Future<void> _runTask() async {
    if (!_isInitialized) return;

    setState(() {
      _status = 'Running task...';
    });

    try {
      // Execute a task using the orchestrator
      final result = await _engine.executeTask(
        TaskRequest(
          taskId: 'task_${DateTime.now().millisecondsSinceEpoch}',
          description: 'Classify this notification as urgent or promotional',
          input: {
            'text': 'Your order #12345 has been shipped!',
          },
          taskType: TaskType.classification,
          context: {
            'screen': 'notifications',
            'timeOfDay': 'morning',
          },
        ),
      );

      setState(() {
        _status = result.success
            ? 'Task completed: ${result.output?.text ?? "Success"}'
            : 'Task failed: ${result.errorMessage}';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _getRecommendation() async {
    if (!_isInitialized) return;

    setState(() {
      _status = 'Getting recommendation...';
    });

    try {
      final recommendation = await _engine.getRecommendation(
        contextType: 'time_of_day',
        contextData: {
          'hour': DateTime.now().hour,
        },
      );

      if (recommendation != null) {
        setState(() {
          _status = 'Recommendation: ${recommendation.title}';
        });
      } else {
        setState(() {
          _status = 'No recommendations available';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _selectModel() async {
    if (!_isInitialized) return;

    setState(() {
      _status = 'Finding best model...';
    });

    try {
      final deviceInfo = await _engine.compatibilityEngine.getDeviceInfo();
      final model = await _engine.getSmallestSuitableModel(
        TaskType.classification,
        deviceInfo: deviceInfo,
        minQuality: 0.8,
      );

      if (model != null) {
        final modelData = await _engine.modelManager.getModel(model.model.id);
        setState(() {
          _status = 'Best model: ${modelData?.name ?? "Unknown"}'
              ' (${model.downloadSize ~/ 1024 ~/ 1024}MB)';
        });
      } else {
        setState(() {
          _status = 'No suitable model found';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _checkHealth() async {
    if (!_isInitialized) return;

    try {
      final health = await _engine.checkHealth();
      setState(() {
        _status = health.isHealthy
            ? 'Health: OK (${health.installedModels} models installed)'
            : 'Health: ${health.components.values.join(", ")}';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI SDK Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _status,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _isInitialized ? _runTask : null,
                  child: const Text('Run Task'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isInitialized ? _getRecommendation : null,
                  child: const Text('Get Recommendation'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isInitialized ? _selectModel : null,
                  child: const Text('Select Model'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isInitialized ? _checkHealth : null,
              child: const Text('Check Health'),
            ),
          ],
        ),
      ),
    );
  }
}
