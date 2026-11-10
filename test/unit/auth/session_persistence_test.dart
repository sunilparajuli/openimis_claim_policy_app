import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openimis_claim_policy_app/data/local/secure_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SecureStorageService storage;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    storage = SecureStorageService();
  });

  test('an active secure session persists across app reloads', () async {
    await storage.saveAuthToken('access-token');
    await storage.saveUserCredentials(username: 'claim-admin');
    await storage.setSessionActive(true);

    final reloadedStorage = SecureStorageService();

    expect(await reloadedStorage.isLoggedIn(), isTrue);
    expect(await reloadedStorage.getUsername(), 'claim-admin');
  });

  test(
    'biometric logout retains credentials without restoring session',
    () async {
      await storage.saveAuthToken('access-token');
      await storage.saveUserCredentials(username: 'claim-admin');
      await storage.setSessionActive(false);

      final reloadedStorage = SecureStorageService();

      expect(await reloadedStorage.hasSavedCredentials(), isTrue);
      expect(await reloadedStorage.isLoggedIn(), isFalse);
    },
  );

  test('older stored sessions remain compatible after upgrade', () async {
    await storage.saveAuthToken('legacy-access-token');

    expect(await storage.isLoggedIn(), isTrue);
  });
}
