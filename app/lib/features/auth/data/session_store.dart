import 'dart:convert';

import 'package:huenote/core/storage/secure_store.dart';
import 'package:huenote/features/auth/domain/account.dart';
import 'package:huenote/features/sync/domain/key_sync.dart';
import 'package:huenote/features/sync/domain/sync_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Signed-in session: token in secure storage, the rest in preferences.
class SessionStore {
  new(this._secure, this._prefs);

  final SecureStore _secure;
  final SharedPreferences _prefs;

  static const _tokenKey = 'auth_token';
  static const _accountKey = 'account_v1';
  static const _lastAccountKey = 'last_account_uuid';

  Future<String?> token() => _secure.read(_tokenKey);

  Account? account() {
    final raw = _prefs.getString(_accountKey);
    return raw == null
        ? null
        : Account.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Account whose data is (or was) on this device.
  String? lastAccountUuid() => _prefs.getString(_lastAccountKey);

  Future<void> save(String token, Account account) async {
    await _secure.write(_tokenKey, token);
    await _prefs.setString(_accountKey, jsonEncode(account.toJson()));
    await _prefs.setString(_lastAccountKey, account.uuid);
  }

  Future<void> clear({required bool forgetDeviceData}) async {
    final uuid = account()?.uuid;
    await _secure.delete(_tokenKey);
    await _prefs.remove(_accountKey);
    if (uuid != null) {
      await _prefs.remove('sync_cursor_$uuid');
      await _prefs.remove('key_version_$uuid');
    }
    if (forgetDeviceData) await _prefs.remove(_lastAccountKey);
  }

  CursorStore cursor(String accountUuid) =>
      _PrefsCursor(_prefs, 'sync_cursor_$accountUuid');

  KeySyncState keyState(String accountUuid) =>
      _PrefsKeyState(_prefs, 'key_version_$accountUuid');
}

final class _PrefsCursor implements CursorStore {
  new(this._prefs, this._key);

  final SharedPreferences _prefs;
  final String _key;

  @override
  Future<int> read() async => _prefs.getInt(_key) ?? 0;

  @override
  Future<void> write(int cursor) => _prefs.setInt(_key, cursor);
}

final class _PrefsKeyState implements KeySyncState {
  new(this._prefs, this._key);

  final SharedPreferences _prefs;
  final String _key;

  @override
  Future<int?> readVersion() async => _prefs.getInt(_key);

  @override
  Future<void> writeVersion(int version) => _prefs.setInt(_key, version);
}
