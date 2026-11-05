import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huenote/core/crypto/crypto_service.dart';
import 'package:huenote/core/storage/secure_store.dart';
import 'package:huenote/features/lock/lock_providers.dart';

import '../../helpers/fakes.dart';

void main() {
  late ProviderContainer container;
  late InMemorySecureStore store;

  ProviderContainer make() => ProviderContainer(
    overrides: [
      secureStoreProvider.overrideWithValue(store),
      cryptoServiceProvider.overrideWithValue(fastCrypto()),
    ],
  );

  setUp(() {
    store = InMemorySecureStore();
    container = make();
  });
  tearDown(() => container.dispose());

  LockController ctrl() => container.read(lockControllerProvider.notifier);

  Future<LockState> state() => container.read(lockControllerProvider.future);

  test('setup -> lock -> unlock, persisted across restarts', () async {
    expect((await state()).hasMasterPassword, isFalse);
    final recovery = await ctrl().setUp('secret1');
    expect(recovery, isNotEmpty);
    expect((await state()).isUnlocked, isTrue);

    ctrl().lock();
    expect((await state()).isUnlocked, isFalse);
    expect(await ctrl().unlock('wrong'), isFalse);
    expect(await ctrl().unlock('secret1'), isTrue);

    final restarted = make();
    addTearDown(restarted.dispose);
    final s = await restarted.read(lockControllerProvider.future);
    expect(s.hasMasterPassword, isTrue);
    expect(s.isUnlocked, isFalse);
  });

  test('seal/unseal through the session', () async {
    await ctrl().setUp('secret1');
    final sealed = await ctrl().seal(textNote('a', text: 'hidden'));
    expect(sealed.text, isEmpty);
    ctrl().lock();
    expect(() => ctrl().unseal(sealed), throwsStateError);
    await ctrl().unlock('secret1');
    expect((await ctrl().unseal(sealed)).text, 'hidden');
  });

  test('change password and reset with recovery key', () async {
    final recovery = await ctrl().setUp('secret1');
    expect(await ctrl().changePassword('bad', 'secret2'), isNull);
    final recovery2 = await ctrl().changePassword('secret1', 'secret2');
    expect(recovery2, isNotNull);

    // Old recovery key was replaced.
    expect(await ctrl().resetWithRecoveryKey(recovery, 'secret3'), isNull);
    expect(await ctrl().resetWithRecoveryKey(recovery2!, 'secret3'), isNotNull);
    ctrl().lock();
    expect(await ctrl().unlock('secret3'), isTrue);
  });
}
