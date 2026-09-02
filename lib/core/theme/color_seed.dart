import 'package:flutter/material.dart';

/// Approved colour-theme seeds for the Settings colour-theme picker.
///
/// Material 3's `ColorScheme.fromSeed` derives the full light/dark role set
/// from one seed colour per theme, so adding a "colour theme" choice is a
/// matter of adding an entry here, not hand-maintaining a full palette.
/// See docs/DESIGN_SYSTEM.md.
enum AppColorSeed {
  calmTeal(
    seedColor: Color(0xFF2A6F77),
    labelEn: 'Calm Teal',
    labelAr: 'أزرق مخضر هادئ',
  ),
  slateIndigo(
    seedColor: Color(0xFF3F4A7A),
    labelEn: 'Slate Indigo',
    labelAr: 'نيلي رمادي',
  ),
  warmTerracotta(
    seedColor: Color(0xFF8A5238),
    labelEn: 'Warm Terracotta',
    labelAr: 'طيني دافئ',
  );

  const AppColorSeed({
    required this.seedColor,
    required this.labelEn,
    required this.labelAr,
  });

  final Color seedColor;
  final String labelEn;
  final String labelAr;
}
