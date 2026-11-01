import 'package:get_it/get_it.dart';
import 'package:ai_sdk/ai_sdk.dart';
import '../firebase_remote_config.dart';
import '../../data/repositories/ai_repository.dart';

final getIt = GetIt.instance;

/// Set up all dependencies
Future<void> setupDependencies() async {
  // Initialize Firebase Remote Config service
  final remoteConfigService = FirebaseRemoteConfigService();
  await remoteConfigService.initialize();
  getIt.registerSingleton<FirebaseRemoteConfigService>(remoteConfigService);

  // Initialize the SDK engine
  final engine = AdaptiveAgentEngine();
  await engine.initialize();
  getIt.registerSingleton<AdaptiveAgentEngine>(engine);

  // Initialize AI repository
  final aiRepository = AiRepository(engine);
  getIt.registerSingleton<AiRepository>(aiRepository);
}
