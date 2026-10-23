import 'package:flutter/material.dart';

import 'home_screen.dart';

/// The Mohingo AI-pack device spike (ADR 0013, Phase B): a throwaway app
/// that downloads a candidate language model, loads it and judges a fixed
/// set of learner answers on the phone, then hands back a report with the
/// memory, speed and judgement quality the decision needs. Nothing here
/// ships in Mohingo.
void main() => runApp(const SpikeApp());

class SpikeApp extends StatelessWidget {
  const SpikeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Mohingo AI-pack spike',
    theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
    home: const HomeScreen(),
  );
}
