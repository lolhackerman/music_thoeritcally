import 'package:flutter/material.dart';
import 'package:music_theoretically/tabs/home_tab.dart';
import 'package:music_theoretically/tabs/scales_tab/scales_tab.dart';
import 'package:music_theoretically/tabs/chords_tab/chords_tab.dart';
import 'package:music_theoretically/tabs/settings_tab.dart';

/// Top-level shell with 4 tabs: Home, Chords, Scales, Settings
class AppShell extends StatefulWidget {
  const AppShell({Key? key}) : super(key: key);

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with SingleTickerProviderStateMixin {
  final GlobalKey _bottomBarKey = GlobalKey();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, animationDuration: Duration.zero);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe
        children: [
          HomeTab(bottomBarKey: _bottomBarKey),
          ChordsTab(bottomBarKey: _bottomBarKey, tabController: _tabController, tabIndex: 1),
          ScalesTab(bottomBarKey: _bottomBarKey, tabController: _tabController, tabIndex: 2),
          SettingsTab(tabController: _tabController, tabIndex: 3),
        ],
      ),
      bottomNavigationBar: Material(
        key: _bottomBarKey,
        color: Theme.of(context).primaryColor,
        child: TabBar(
          controller: _tabController,
          onTap: (index) {
            _tabController.index = index; // Direct index change with no animation
          },
          indicator: const BoxDecoration(), // Remove the underline indicator
          tabs: const [
            Tab(text: 'Home'),
            Tab(text: 'Chords'),
            Tab(text: 'Scales'),
            Tab(text: 'Settings'),
          ],
        ),
      ),
    );
  }
}
