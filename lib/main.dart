import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_screen.dart';
import 'state/game_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final prefs = await SharedPreferences.getInstance();
  runApp(FashionStarApp(state: GameState(prefs)));
}

class FashionStarApp extends StatelessWidget {
  const FashionStarApp({super.key, required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    return GameScope(
      state: state,
      child: MaterialApp(
        title: 'Fashion Star',
        debugShowCheckedModeBanner: false,
        // Let the horizontal item trays scroll with a mouse/trackpad drag too
        // (web and desktop); touch already works.
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          dragDevices: PointerDeviceKind.values.toSet(),
        ),
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF4FA3),
            primary: const Color(0xFFE0388E),
          ),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
