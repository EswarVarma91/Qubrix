import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:ai_sdk/ai_sdk.dart';
import '../../data/repositories/ai_repository.dart';

final getIt = GetIt.instance;

/// Initialize all dependencies
Future<void> initializeDependencies() async {
  // AI SDK Engine
  final engine = AdaptiveAgentEngine(
    config: AgentEngineConfig(
      enableModelManagement: true,
      enablePersonalization: true,
      enableRecommendations: true,
      enableAutomation: true,
      privacyMode: PrivacyMode.localFirst,
      minModelQuality: 0.7,
    ),
  );
  await engine.initialize();

  getIt.registerSingleton<AdaptiveAgentEngine>(engine);

  // Register sample actions
  final engineRef = getIt<AdaptiveAgentEngine>();
  engineRef.registerActions([
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

  // Repositories
  getIt.registerLazySingleton<AiRepository>(() => AiRepository(getIt()));
}

/// GetX bindings for screens
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(
      () => HomeController(
        engine: Get.find<AdaptiveAgentEngine>(),
        repository: Get.find<AiRepository>(),
      ),
      tag: 'homeController',
    );
  }
}
