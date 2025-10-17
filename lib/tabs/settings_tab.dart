import 'package:flutter/material.dart';
import '../state/app_settings.dart';
import 'settings_sections.dart';
import 'settings_components.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // Slight size dial-down in landscape
    final scale = isLandscape ? 0.88 : 1.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            NaturalsPaletteSection(
              onReset: settings.resetToDefaults,
              scale: scale,
            ),
            const SizedBox(height: 24),
            HighlightColorsSection(
              onReset: settings.resetHighlightColors,
              scale: scale,
            ),
            const SizedBox(height: 24),
            FretboardMarkersSection(
              onReset: () {
                settings.resetInlayDotColor();
                settings.resetMarkerColors();
              },
              scale: isLandscape ? 1.3 : 1.5,
            ),
            const SizedBox(height: 24),
            const HintCard(),
          ],
        ),
      ),
    );
  }
}
