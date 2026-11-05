/// Persisted as int — never renumber.
enum NoteType {
  text(0),
  checklist(1);

  new(this.value);

  final int value;

  static NoteType fromValue(int value) =>
      value == checklist.value ? checklist : text;
}
