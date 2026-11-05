import 'package:flutter_test/flutter_test.dart';
import 'package:huenote/core/utils/id_generator.dart';

void main() {
  const gen = UuidV7Generator();

  test('generates UUID v7', () {
    final id = gen.newId();
    expect(
      id,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });

  test('ids are unique and time-sortable', () async {
    final first = gen.newId();
    await Future<void>.delayed(const Duration(milliseconds: 2));
    final second = gen.newId();
    expect(first, isNot(second));
    expect(first.compareTo(second), lessThan(0));
  });
}
