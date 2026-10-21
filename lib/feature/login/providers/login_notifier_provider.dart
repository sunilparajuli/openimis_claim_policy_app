import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod_template/feature/login/models/login_request_model.dart';
import 'package:flutter_riverpod_template/feature/login/models/login_response_model.dart';
import 'package:flutter_riverpod_template/feature/login/repositories/openimis_auth_repository.dart';
import 'package:flutter_riverpod_template/feature/shared/providers/user_session_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'login_notifier_provider.g.dart';

/// Modern Riverpod 3.0 AsyncNotifier for login state management
/// This demonstrates:
/// - AsyncNotifier for async operations
/// - Proper use of AsyncValue (loading/data/error states)
/// - No need for custom APIResultState - AsyncValue handles it
/// - Clean error handling
@riverpod
class LoginNotifier extends _$LoginNotifier {
  @override
  Future<LoginResponseModel?> build() async {
    debugPrint('LoginNotifier: Initial state (not logged in)');
    // Return null initially (no user logged in)
    return null;
  }

  /// Login method using modern AsyncNotifier pattern
  /// AsyncValue automatically handles loading/error/data states
  Future<void> login(LoginRequestModel loginRequestModel) async {
    debugPrint(
      'LoginNotifier: Login requested for ${loginRequestModel.userName}',
    );

    // Set state to loading - AsyncValue handles this automatically
    state = const AsyncLoading();

    // Alternative: If you want to preserve previous data while loading
    // state = AsyncValue.loading().copyWithPrevious(state);

    try {
      final auth = await ref
          .read(openImisAuthRepositoryProvider)
          .login(loginRequestModel);
      final loginResponse = LoginResponseModel(
        id: auth.expiresOn,
        userName: loginRequestModel.userName.trim(),
      );

      await ref
          .read(userSessionProvider.notifier)
          .login(
            username: loginResponse.userName,
            loginMethod: 'openimis',
            token: auth.token,
          );

      // Update state with data - AsyncValue wraps it automatically
      state = AsyncData(loginResponse);

      debugPrint(
        'LoginNotifier: Login successful for ${loginResponse.userName}',
      );
    } catch (error, stackTrace) {
      debugPrint('LoginNotifier: Login failed - $error');

      // AsyncValue automatically handles errors
      state = AsyncError(error, stackTrace);

      // Optionally rethrow if you want calling code to handle it
      // rethrow;
    }
  }

  /// Logout method
  void logout() {
    debugPrint('LoginNotifier: Logging out');
    state = const AsyncData(null);
  }

  /// Reset error state
  void clearError() {
    if (state.hasError) {
      debugPrint('LoginNotifier: Clearing error state');
      state = const AsyncData(null);
    }
  }
}
