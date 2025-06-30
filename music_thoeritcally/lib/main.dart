import 'package:flutter/material.dart';
import 'pages/fretboard_page.dart';

void main() {
  runApp(const GuitarApp());
}

class GuitarApp extends StatelessWidget {
  const GuitarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guitar Fretboard',
      theme: ThemeData.dark(),
      home: const FretboardPage(),
    );
  }
}
