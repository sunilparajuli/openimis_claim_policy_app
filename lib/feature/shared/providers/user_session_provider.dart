import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod_template/data/local/secure_storage_service.dart';

part 'user_session_provider.g.dart';

/// User session state with secure storage support
class UserSession {
  final String? username;
  final String? email;
  final bool isGuest;
  final String loginMethod; // 'email', 'google', 'guest'
  final String? token; // JWT token for authenticated users
  final String? claimAdminCode;
  final String? claimAdminName;
  final String? healthFacilityCode;
  final String? healthFacilityName;
  final String? enrolmentOfficerCode;

  const UserSession({
    this.username,
    this.email,
    this.isGuest = false,
    this.loginMethod = 'guest',
    this.token,
    this.claimAdminCode,
    this.claimAdminName,
    this.healthFacilityCode,
    this.healthFacilityName,
    this.enrolmentOfficerCode,
  });

  UserSession copyWith({
    String? username,
    String? email,
    bool? isGuest,
    String? loginMethod,
    String? token,
    String? claimAdminCode,
    String? claimAdminName,
    String? healthFacilityCode,
    String? healthFacilityName,
    String? enrolmentOfficerCode,
  }) {
    return UserSession(
      username: username ?? this.username,
      email: email ?? this.email,
      isGuest: isGuest ?? this.isGuest,
      loginMethod: loginMethod ?? this.loginMethod,
      token: token ?? this.token,
      claimAdminCode: claimAdminCode ?? this.claimAdminCode,
      claimAdminName: claimAdminName ?? this.claimAdminName,
      healthFacilityCode: healthFacilityCode ?? this.healthFacilityCode,
      healthFacilityName: healthFacilityName ?? this.healthFacilityName,
      enrolmentOfficerCode: enrolmentOfficerCode ?? this.enrolmentOfficerCode,
    );
  }

  bool get isAuthenticated => !isGuest && token != null;
}

/// User session notifier with secure storage persistence
@Riverpod(keepAlive: true)
class UserSessionNotifier extends _$UserSessionNotifier {
  late final SecureStorageService _storage;

  @override
  Future<UserSession?> build() async {
    _storage = ref.read(secureStorageServiceProvider);

    // Try to restore session from secure storage on app start
    final isLoggedIn = await _storage.isLoggedIn();
    if (isLoggedIn) {
      final username = await _storage.getUsername();
      final email = await _storage.getEmail();
      final token = await _storage.getAuthToken();
      final claimAdminCode = await _storage.getClaimAdminCode();
      final claimAdminName = await _storage.getClaimAdminName();
      final healthFacilityCode = await _storage.getHealthFacilityCode();
      final healthFacilityName = await _storage.getHealthFacilityName();
      var enrolmentOfficerCode = await _storage.getEnrolmentOfficerCode();

      // Older builds incorrectly used the login username (for example,
      // "Admin") as an enrolment officer code. They are separate identities.
      if (enrolmentOfficerCode == username) {
        await _storage.deleteEnrolmentOfficerCode();
        enrolmentOfficerCode = null;
      }

      if (username != null) {
        return UserSession(
          username: username,
          email: email,
          isGuest: false,
          loginMethod: 'email',
          token: token,
          claimAdminCode: claimAdminCode,
          claimAdminName: claimAdminName,
          healthFacilityCode: healthFacilityCode,
          healthFacilityName: healthFacilityName,
          enrolmentOfficerCode: enrolmentOfficerCode,
        );
      }
    }

    return null;
  }

  Future<void> configureClaimAdministrator({
    required String code,
    required String name,
    required String healthFacilityCode,
    required String healthFacilityName,
  }) async {
    final current = state.value;
    if (current == null) return;
    await _storage.saveClaimAdministrator(
      code: code,
      name: name,
      healthFacilityCode: healthFacilityCode,
      healthFacilityName: healthFacilityName,
    );
    state = AsyncData(
      current.copyWith(
        claimAdminCode: code,
        claimAdminName: name,
        healthFacilityCode: healthFacilityCode,
        healthFacilityName: healthFacilityName,
      ),
    );
  }

  Future<void> clearClaimAdministrator() async {
    final current = state.value;
    if (current == null) return;
    await _storage.clearClaimAdministrator();
    state = AsyncData(
      UserSession(
        username: current.username,
        email: current.email,
        isGuest: current.isGuest,
        loginMethod: current.loginMethod,
        token: current.token,
        enrolmentOfficerCode: current.enrolmentOfficerCode,
      ),
    );
  }

  /// Login with credentials and save to secure storage
  Future<void> login({
    required String username,
    String? email,
    required String loginMethod,
    String? token,
  }) async {
    final session = UserSession(
      username: username,
      email: email,
      isGuest: loginMethod == 'guest',
      loginMethod: loginMethod,
      token: token,
      enrolmentOfficerCode: null,
    );

    // Save to secure storage if not a guest
    if (!session.isGuest && token != null) {
      await _storage.saveAuthToken(token);
      await _storage.saveUserCredentials(username: username, email: email);
    }

    state = AsyncData(session);
  }

  /// Logout and clear secure storage
  Future<void> logout() async {
    await _storage.clearAll();
    state = const AsyncData(null);
  }

  /// Update user profile
  Future<void> updateProfile({String? username, String? email}) async {
    final currentState = state.value;
    if (currentState != null) {
      final updatedSession = currentState.copyWith(
        username: username,
        email: email,
      );

      // Update secure storage
      if (!updatedSession.isGuest) {
        await _storage.saveUserCredentials(
          username: username ?? currentState.username ?? '',
          email: email ?? currentState.email,
        );
      }

      state = AsyncData(updatedSession);
    }
  }

  /// Save new auth token (for token refresh)
  Future<void> saveToken(String token) async {
    await _storage.saveAuthToken(token);
    final currentState = state.value;
    if (currentState != null) {
      state = AsyncData(currentState.copyWith(token: token));
    }
  }

  /// Check if session is valid
  bool get isAuthenticated => state.value?.isAuthenticated ?? false;
}
