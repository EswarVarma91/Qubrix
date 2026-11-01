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

  // Initialize AI repository
  final aiRepository = AiRepository(engine);
  getIt.registerSingleton<AiRepository>(aiRepository);
}

/// GetX binding for the home route.
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(HomeController());
  }
}

/// GetX binding for the settings route.
class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(HomeController());
  }
}
