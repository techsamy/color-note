import 'package:flutter/material.dart';
import 'package:huenote/app/theme/note_palette.dart';

/// Design tokens. Widgets must use these — no hard-coded colours/sizes.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class AppRadius {
  static const card = 12.0;
  static const sheet = 28.0;
}

abstract final class AppTheme {
  /// Brand seed for app chrome (placeholder until branding is final).
  static const seed = Color(0xFFF2B33D);

  static ThemeData light() => _build(Brightness.light, NotePalette.light);

  static ThemeData dark() => _build(Brightness.dark, NotePalette.dark);

  static ThemeData _build(Brightness brightness, NotePalette palette) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      extensions: [palette],
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),
    );
  }
}
