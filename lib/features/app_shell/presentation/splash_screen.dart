import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/brand_mark.dart';

/// Shown while the curriculum bundle is loading — see
/// docs/ARCHITECTURE.md's content-loading strategy. The app icon on the
/// page colour, as the native launch screen shows it, so start-up reads as
/// one continuous screen rather than a flash of an empty spinner.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandMark(size: 96),
            SizedBox(height: AppSpace.lg),
            SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
