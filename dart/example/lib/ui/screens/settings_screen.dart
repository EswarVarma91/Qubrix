import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';

/// Settings screen with GetX navigation
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              leading: const Icon(Icons.person),
              title: const Text(AppStrings.personalizationEnabled),
              subtitle: const Text('Learn from permitted app activity'),
              value: true,
              onChanged: (value) {},
            ),
          ),
          const Divider(),
          Card(
            child: SwitchListTile(
              leading: const Icon(Icons.recommend),
              title: const Text(AppStrings.recommendationsDisabled),
              subtitle: const Text('Get AI-powered suggestions'),
              value: true,
              onChanged: (value) {},
            ),
          ),
          const Divider(),
          Card(
            child: SwitchListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Local Processing'),
              subtitle: const Text('Process data on device'),
              value: true,
              onChanged: (value) {},
            ),
          ),
          const Divider(),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              subtitle: const Text('AI SDK Demo v1.0.0'),
              onTap: () {},
            ),
          ),
          const Divider(),
          Card(
            child: ListTile(
              leading: const Icon(Icons.privacy),
              title: const Text('Privacy Policy'),
              onTap: () {},
            ),
          ),
          const Divider(),
          Card(
            child: ListTile(
              leading: const Icon(Icons.code),
              title: const Text('Open Source Licenses'),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}

/// Settings binding for dependency injection
class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    // Add any dependencies needed for settings screen
  }
}
