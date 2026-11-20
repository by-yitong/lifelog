import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/analytics/app_analytics.dart';
import 'features/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 预热液态玻璃着色器，避免首帧玻璃闪成磨砂
  await LiquidGlassShaders.ensureLoaded();
  final prefs = await SharedPreferences.getInstance();
  await AppAnalytics.initFromPrefs(prefs);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const LifelogApp(),
    ),
  );
}
