import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'models/workout_state.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Full screen immersive mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(
    ChangeNotifierProvider(
      create: (_) => WorkoutState(),
      child: const GoWorkoutApp(),
    ),
  );
}

class GoWorkoutApp extends StatelessWidget {
  const GoWorkoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GO Workout',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FF88),
          secondary: Color(0xFF3742FA),
          surface: Color(0xFF12121E),
          error: Color(0xFFFF4757),
        ),
        fontFamily: 'SF Pro Display',
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
