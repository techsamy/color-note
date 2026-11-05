import 'package:flutter_test/flutter_test.dart';
import 'package:huenote/features/notes/domain/note_color.dart';
import 'package:huenote/features/settings/data/settings_repository.dart';
import 'package:huenote/features/settings/domain/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('defaults, save/load, corrupt value falls back', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = SettingsRepository(await SharedPreferences.getInstance());
    expect(repo.load(), const AppSettings());

    const changed = AppSettings(
      defaultColor: NoteColor.blue,
      fontSize: NoteFontSize.large,
    );
    await repo.save(changed);
    expect(repo.load(), changed);

    SharedPreferences.setMockInitialValues({
      'app_settings_v1': '{"themeMode":"neon"}',
    });
    final broken = SettingsRepository(await SharedPreferences.getInstance());
    expect(broken.load(), const AppSettings());
  });
}
