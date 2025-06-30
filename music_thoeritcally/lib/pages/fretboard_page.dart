import 'package:flutter/material.dart';
import '../../widgets/fretboard_widget.dart';

class FretboardPage extends StatelessWidget {
  const FretboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guitar Fretboard'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(12.0),
        child: FretboardWidget(),
      ),
    );
  }
}
