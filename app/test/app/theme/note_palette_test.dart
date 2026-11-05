import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huenote/app/theme/note_palette.dart';
import 'package:huenote/features/notes/domain/note_color.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  for (final (name, palette) in [
    ('light', NotePalette.light),
    ('dark', NotePalette.dark),
  ]) {
    test(
      '$name palette: every note colour has text contrast >= 4.5 (NFR-5)',
      () {
        for (final c in NoteColor.values) {
          final s = palette[c];
          expect(
            contrast(s.background, s.foreground),
            greaterThanOrEqualTo(4.5),
            reason: '$name/${c.name}',
          );
        }
      },
    );
  }
}
