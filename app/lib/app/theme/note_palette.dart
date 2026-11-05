import 'package:flutter/material.dart';
import 'package:huenote/features/notes/domain/note_color.dart';

/// Colours used to paint a note of a given [NoteColor].
@immutable
final class NoteSwatch {
  const new({
    required this.background,
    required this.foreground,
    required this.accent,
  });

  /// Card / editor background.
  final Color background;

  /// Text on [background]; must keep contrast >= 4.5:1 (NFR-5).
  final Color foreground;

  /// Saturated swatch for dots, chips and calendar markers.
  final Color accent;
}

/// Fixed note palette (not derived from the Material seed), as a
/// [ThemeExtension] so widgets read it via `NotePalette.of(context)`.
@immutable
final class NotePalette extends ThemeExtension<NotePalette> {
  const new _(this._swatches);

  static const _darkText = Color(0xFF1F1F1F);
  static const _lightText = Color(0xFFE8EAED);

  static const light = NotePalette._({
    NoteColor.red: NoteSwatch(
      background: Color(0xFFF8C9C4),
      foreground: _darkText,
      accent: Color(0xFFE53935),
    ),
    NoteColor.orange: NoteSwatch(
      background: Color(0xFFFBD9B0),
      foreground: _darkText,
      accent: Color(0xFFFB8C00),
    ),
    NoteColor.yellow: NoteSwatch(
      background: Color(0xFFFFF1A8),
      foreground: _darkText,
      accent: Color(0xFFFDD835),
    ),
    NoteColor.green: NoteSwatch(
      background: Color(0xFFCDEBC5),
      foreground: _darkText,
      accent: Color(0xFF43A047),
    ),
    NoteColor.blue: NoteSwatch(
      background: Color(0xFFC5DDF8),
      foreground: _darkText,
      accent: Color(0xFF1E88E5),
    ),
    NoteColor.purple: NoteSwatch(
      background: Color(0xFFE0CCF2),
      foreground: _darkText,
      accent: Color(0xFF8E24AA),
    ),
    NoteColor.black: NoteSwatch(
      background: Color(0xFF3A3A3A),
      foreground: Color(0xFFFFFFFF),
      accent: Color(0xFF212121),
    ),
    NoteColor.grey: NoteSwatch(
      background: Color(0xFFDADADA),
      foreground: _darkText,
      accent: Color(0xFF9E9E9E),
    ),
    NoteColor.white: NoteSwatch(
      background: Color(0xFFFFFFFF),
      foreground: _darkText,
      accent: Color(0xFFBDBDBD),
    ),
  });

  static const dark = NotePalette._({
    NoteColor.red: NoteSwatch(
      background: Color(0xFF5C2B29),
      foreground: _lightText,
      accent: Color(0xFFEF5350),
    ),
    NoteColor.orange: NoteSwatch(
      background: Color(0xFF614A19),
      foreground: _lightText,
      accent: Color(0xFFFFA726),
    ),
    NoteColor.yellow: NoteSwatch(
      background: Color(0xFF635D19),
      foreground: _lightText,
      accent: Color(0xFFFFEE58),
    ),
    NoteColor.green: NoteSwatch(
      background: Color(0xFF345920),
      foreground: _lightText,
      accent: Color(0xFF66BB6A),
    ),
    NoteColor.blue: NoteSwatch(
      background: Color(0xFF1E3A5F),
      foreground: _lightText,
      accent: Color(0xFF42A5F5),
    ),
    NoteColor.purple: NoteSwatch(
      background: Color(0xFF42275E),
      foreground: _lightText,
      accent: Color(0xFFAB47BC),
    ),
    NoteColor.black: NoteSwatch(
      background: Color(0xFF000000),
      foreground: _lightText,
      accent: Color(0xFF424242),
    ),
    NoteColor.grey: NoteSwatch(
      background: Color(0xFF3C3F43),
      foreground: _lightText,
      accent: Color(0xFF9E9E9E),
    ),
    NoteColor.white: NoteSwatch(
      background: Color(0xFFE8E8E8),
      foreground: _darkText,
      accent: Color(0xFFF5F5F5),
    ),
  });

  final Map<NoteColor, NoteSwatch> _swatches;

  NoteSwatch operator [](NoteColor color) => _swatches[color]!;

  static NotePalette of(BuildContext context) =>
      Theme.of(context).extension<NotePalette>() ?? light;

  @override
  NotePalette copyWith() => this;

  @override
  NotePalette lerp(NotePalette? other, double t) =>
      t < 0.5 ? this : (other ?? this);
}
