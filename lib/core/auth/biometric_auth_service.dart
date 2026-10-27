import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openimis_claim_policy_app/data/local/secure_storage_service.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  BiometricAuthService(this._storage, {LocalAuthentication? localAuth})
    : _localAuth = localAuth ?? LocalAuthentication();

  final SecureStorageService _storage;
  final LocalAuthentication _localAuth;

  Future<bool> isAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics &&
          (await _localAuth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access openIMIS',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> isEnabled() => _storage.isBiometricEnabled();
  Future<bool> wasSetupOffered() => _storage.wasBiometricSetupOffered();
  Future<void> markSetupOffered() => _storage.setBiometricSetupOffered(true);
  Future<void> setEnabled(bool enabled) =>
      _storage.setBiometricEnabled(enabled);
}

final biometricAuthServiceProvider = Provider<BiometricAuthService>((ref) {
  return BiometricAuthService(ref.read(secureStorageServiceProvider));
});

/// Whether the device supports biometric authentication. Enrollment and app
/// enablement are checked separately when authentication is requested.
final biometricAvailableProvider = FutureProvider<bool>((ref) {
  return ref.read(biometricAuthServiceProvider).isSupported();
});

final biometricEnabledProvider =
    AsyncNotifierProvider<BiometricEnabledNotifier, bool>(
      BiometricEnabledNotifier.new,
    );

class BiometricEnabledNotifier extends AsyncNotifier<bool> {
  BiometricAuthService get _service => ref.read(biometricAuthServiceProvider);

  @override
  Future<bool> build() => _service.isEnabled();

  Future<bool> enable() async {
    if (!await _service.isAvailable()) return false;
    if (!await _service.authenticate()) return false;
    await _service.setEnabled(true);
    state = const AsyncData(true);
    return true;
  }

  Future<void> disable() async {
    await _service.setEnabled(false);
    state = const AsyncData(false);
  }

  void reset() {
    state = const AsyncData(false);
  }

  Future<void> setEnabledAfterAuthentication() async {
    await _service.setEnabled(true);
    state = const AsyncData(true);
  }
}
