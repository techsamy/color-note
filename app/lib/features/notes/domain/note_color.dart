/// The 9 note colours. `value` is persisted and synced — NEVER reorder,
/// renumber or reuse values. New colours get new values. (docs/04 §1)
enum NoteColor {
  red(0),
  orange(1),
  yellow(2),
  green(3),
  blue(4),
  purple(5),
  black(6),
  grey(7),
  white(8);

  new(this.value);

  final int value;

  static NoteColor fromValue(int value) => NoteColor.values.firstWhere(
    (c) => c.value == value,
    // Unknown colour from a newer app version: fall back, don't crash.
    orElse: () => NoteColor.yellow,
  );
}
