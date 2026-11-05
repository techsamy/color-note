import 'package:flutter/material.dart';
import 'package:huenote/features/settings/domain/app_settings.dart';

/// Note body text honours the font-size setting (FR-W2); app chrome doesn't.
TextStyle noteBodyStyle(BuildContext context, NoteFontSize size, Color color) {
  final base = Theme.of(context).textTheme.bodyLarge!;
  return base.copyWith(
    color: color,
    fontSize: (base.fontSize ?? 16) * size.scale,
    height: 1.4,
  );
}

TextStyle noteTitleStyle(BuildContext context, NoteFontSize size, Color color) {
  final base = Theme.of(context).textTheme.titleLarge!;
  return base.copyWith(
    color: color,
    fontSize: (base.fontSize ?? 22) * size.scale,
    fontWeight: FontWeight.w600,
  );
}
