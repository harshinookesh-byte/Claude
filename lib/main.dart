import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ads/ad_service.dart';
import 'screens/home_screen.dart';
import 'state/game_state.dart';
import 'theme/tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Draw edge to edge; screens keep their content inside the safe area.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  final prefs = await SharedPreferences.getInstance();
  final ads = adsSupported ? AdMobService() : NoAdService();
  runApp(FashionStarApp(state: GameState(prefs), ads: ads));
  // Consent + SDK start-up runs in the background; ads appear once ready.
  if (ads is AdMobService) ads.init();
}

class FashionStarApp extends StatelessWidget {
  const FashionStarApp({super.key, required this.state, required this.ads});

  final GameState state;
  final AdService ads;

  @override
  Widget build(BuildContext context) {
    return AdScope(
      ads: ads,
      child: GameScope(
        state: state,
        child: MaterialApp(
          title: 'Fashion Star',
          debugShowCheckedModeBanner: false,
          // Let the horizontal item trays scroll with a mouse/trackpad drag too
          // (web and desktop); touch already works.
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            dragDevices: PointerDeviceKind.values.toSet(),
          ),
          theme: buildTheme(),
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
