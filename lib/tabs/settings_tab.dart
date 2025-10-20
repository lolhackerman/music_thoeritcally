import 'package:flutter/material.dart';
import '../state/app_settings.dart';
import 'package:music_theoretically/widgets/fade_on_mount.dart';
import 'settings_sections.dart';
import 'settings_components.dart';

class SettingsTab extends StatefulWidget {
  final TabController? tabController;
  final int? tabIndex;
  const SettingsTab({super.key, this.tabController, this.tabIndex});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // Slight size dial-down in landscape
    final scale = isLandscape ? 0.88 : 1.0;

    return FadeOnMount(
      tabController: widget.tabController,
      tabIndex: widget.tabIndex,
      child: Scaffold(
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
      ),
    );
  }
}
