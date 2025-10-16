import 'package:flutter/material.dart';
import 'screens/app_shell.dart';
import 'state/app_settings.dart'; // <-- add

void main() {
  // debugPaintSizeEnabled = true; // Visual debug outlines
  runApp(const MusicTheoreticallyApp());
}

class MusicTheoreticallyApp extends StatelessWidget {
  const MusicTheoreticallyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Keep EXACTLY your ThemeData.dark() setup
    return AppSettingsScope( // <-- add global settings scope
      notifier: AppSettings(),
      child: MaterialApp(
        // title: 'Music Theoretically',
        theme: ThemeData.dark(),
        home: OrientationBuilder(
          builder: (context, orientation) {
            return const AppShell();
          },
        ),
      ),
    );
  }
}
