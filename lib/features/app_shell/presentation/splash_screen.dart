import 'package:flutter/material.dart';

/// Shown while the curriculum bundle is loading — see
/// docs/ARCHITECTURE.md's content-loading strategy.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
