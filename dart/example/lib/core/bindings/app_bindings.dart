import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:qubrix/qubrix.dart';
import '../firebase_remote_config.dart';
import '../../data/repositories/ai_repository.dart';
import '../../ui/controllers/home_controller.dart';

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

  // Initialize AI repository, reusing the Remote Config service so downloads
  // use the HuggingFace URL published in Firebase.
  final aiRepository = AiRepository(engine, remoteConfigService);
  getIt.registerSingleton<AiRepository>(aiRepository);

  // Controllers resolve their services through GetX, so expose them there as
  // well and keep one shared HomeController for every route.
  Get.put(remoteConfigService);
  Get.put(engine);
  Get.put(aiRepository);
  Get.put(HomeController(), permanent: true);
}
