import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'state/app_state.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'firebase_options.dart';
import 'services/gemini_advisor_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  await GeminiAdvisorService.initCache();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await FirebaseAppCheck.instance.activate(
    // ignore: deprecated_member_use
    appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
    // ignore: deprecated_member_use
    androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
  );

  final remoteConfig = FirebaseRemoteConfig.instance;
  await remoteConfig.setConfigSettings(RemoteConfigSettings(
    fetchTimeout: const Duration(minutes: 1),
    minimumFetchInterval: const Duration(hours: 1),
  ));
  await remoteConfig.fetchAndActivate();

  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ImmoState(prefs)),
        ChangeNotifierProvider(create: (_) => AutoState(prefs)),
        ChangeNotifierProvider(create: (_) => ConsoState(prefs)),
        ChangeNotifierProvider(create: (_) => LombardState(prefs)),
        ChangeNotifierProvider(create: (_) => SuccessionState(prefs)),
        ChangeNotifierProvider(create: (_) => EpargneState(prefs)),
      ],
      child: const SimulateurApp(),
    ),
  );
}

class SimulateurApp extends StatelessWidget {
  const SimulateurApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Patrimonia',
      debugShowCheckedModeBanner: false,
      theme: SimTheme.theme,
      home: const HomeScreen(),
    );
  }
}
