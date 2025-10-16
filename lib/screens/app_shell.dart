import 'package:flutter/material.dart';
import 'package:music_theoretically/tabs/home_tab.dart';
import 'package:music_theoretically/tabs/scales_tab/scales_tab.dart';
import 'package:music_theoretically/tabs/chords_tab/chords_tab.dart'; // <-- add
import 'package:music_theoretically/tabs/settings_tab.dart'; // keep this

/// Top-level shell with 4 tabs: Home, Scales, Chords, Settings
class AppShell extends StatefulWidget {
  const AppShell({Key? key}) : super(key: key);

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey _bottomBarKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, // <-- was 3
      child: Scaffold(
        extendBody: true,
        body: TabBarView(
          children: [
            HomeTab(bottomBarKey: _bottomBarKey),
            const ScalesTab(),
            const ChordsTab(), // <-- new
            const SettingsTab(),
          ],
        ),
        bottomNavigationBar: Material(
          key: _bottomBarKey,
          color: Theme.of(context).primaryColor,
          child: const TabBar(
            tabs: [
              Tab(text: 'Home'),
              Tab(text: 'Scales'),
              Tab(text: 'Chords'), // <-- new
              Tab(text: 'Settings'),
            ],
          ),
        ),
      ),
    );
  }
}
