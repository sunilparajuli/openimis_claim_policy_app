import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_storage_service.g.dart';

/// Secure storage service for handling sensitive data
/// Uses platform-specific secure storage:
/// - Android: EncryptedSharedPreferences with AES encryption
/// - iOS: Keychain
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      // Using default secure settings (AES encryption)
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Auth token keys
  static const String _authTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _usernameKey = 'username';
  static const String _emailKey = 'email';
  static const String _claimAdminCodeKey = 'claim_admin_code';
  static const String _claimAdminNameKey = 'claim_admin_name';
  static const String _healthFacilityCodeKey = 'health_facility_code';
  static const String _healthFacilityNameKey = 'health_facility_name';
  static const String _enrolmentOfficerCodeKey = 'enrolment_officer_code';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _biometricSetupOfferedKey = 'biometric_setup_offered';

  /// Save authentication token
  Future<void> saveAuthToken(String token) async {
    await _storage.write(key: _authTokenKey, value: token);
  }

  /// Get authentication token
  Future<String?> getAuthToken() async {
    return await _storage.read(key: _authTokenKey);
  }

  /// Delete authentication token
  Future<void> deleteAuthToken() async {
    await _storage.delete(key: _authTokenKey);
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Delete refresh token
  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }

  /// Save user credentials
  Future<void> saveUserCredentials({
    required String username,
    String? email,
  }) async {
    await _storage.write(key: _usernameKey, value: username);
    if (email != null) {
      await _storage.write(key: _emailKey, value: email);
    }
  }

  /// Get username
  Future<String?> getUsername() async {
    return await _storage.read(key: _usernameKey);
  }

  /// Get email
  Future<String?> getEmail() async {
    return await _storage.read(key: _emailKey);
  }

  Future<void> saveClaimAdministrator({
    required String code,
    required String name,
    required String healthFacilityCode,
    required String healthFacilityName,
  }) async {
    await _storage.write(key: _claimAdminCodeKey, value: code);
    await _storage.write(key: _claimAdminNameKey, value: name);
    await _storage.write(
      key: _healthFacilityCodeKey,
      value: healthFacilityCode,
    );
    await _storage.write(
      key: _healthFacilityNameKey,
      value: healthFacilityName,
    );
  }

  Future<String?> getClaimAdminCode() => _storage.read(key: _claimAdminCodeKey);
  Future<String?> getClaimAdminName() => _storage.read(key: _claimAdminNameKey);
  Future<String?> getHealthFacilityCode() =>
      _storage.read(key: _healthFacilityCodeKey);
  Future<String?> getHealthFacilityName() =>
      _storage.read(key: _healthFacilityNameKey);

  Future<void> clearClaimAdministrator() async {
    await Future.wait([
      _storage.delete(key: _claimAdminCodeKey),
      _storage.delete(key: _claimAdminNameKey),
      _storage.delete(key: _healthFacilityCodeKey),
      _storage.delete(key: _healthFacilityNameKey),
    ]);
  }

  Future<void> saveEnrolmentOfficerCode(String code) =>
      _storage.write(key: _enrolmentOfficerCodeKey, value: code);

  Future<String?> getEnrolmentOfficerCode() =>
      _storage.read(key: _enrolmentOfficerCodeKey);

  Future<void> deleteEnrolmentOfficerCode() =>
      _storage.delete(key: _enrolmentOfficerCodeKey);

  Future<void> setBiometricEnabled(bool enabled) =>
      _storage.write(key: _biometricEnabledKey, value: enabled.toString());

  Future<bool> isBiometricEnabled() async =>
      await _storage.read(key: _biometricEnabledKey) == 'true';

  Future<void> setBiometricSetupOffered(bool offered) =>
      _storage.write(key: _biometricSetupOfferedKey, value: offered.toString());

  Future<bool> wasBiometricSetupOffered() async =>
      await _storage.read(key: _biometricSetupOfferedKey) == 'true';

  /// Clear all stored data
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Check if user is logged in (has auth token)
  Future<bool> isLoggedIn() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }
}

/// Provider for SecureStorageService
@riverpod
SecureStorageService secureStorageService(Ref ref) {
  return SecureStorageService();
}
