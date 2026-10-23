import 'package:flutter/material.dart';

/// The app icon as it appears on the phone's home screen, at [size] — the
/// one image of Mohingo's identity inside the app (splash, first-run
/// agreement, About). Decorative: screen readers skip it, since the name
/// is always written beside it.
class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 72, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.24),
        child: Image.asset(
          'assets/brand/mohingo_mark.png',
          width: size,
          height: size,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}
