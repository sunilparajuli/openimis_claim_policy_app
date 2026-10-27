import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openimis_claim_policy_app/core/localization/app_localizations.dart';
import 'package:openimis_claim_policy_app/core/localization/language_selector_widget.dart';
import 'package:openimis_claim_policy_app/core/auth/biometric_auth_service.dart';
import 'package:openimis_claim_policy_app/feature/login/models/login_request_model.dart';
import 'package:openimis_claim_policy_app/feature/login/models/login_response_model.dart';
import 'package:openimis_claim_policy_app/feature/login/providers/login_notifier_provider.dart';
import 'package:openimis_claim_policy_app/feature/shared/navigation/app_router.gr.dart';
import 'package:openimis_claim_policy_app/feature/shared/utils/ui_utils.dart';
import 'package:openimis_claim_policy_app/feature/shared/widgets/app_widgets.dart';
import 'package:openimis_claim_policy_app/feature/shared/providers/user_session_provider.dart';

@RoutePage()
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({required this.title, super.key});

  final String title;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _userNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _completingLogin = false;
  bool _authenticatingBiometric = false;

  @override
  void dispose() {
    _userNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<LoginResponseModel?>>(loginProvider, (
      previous,
      next,
    ) {
      switch (next) {
        case AsyncData(:final value) when value != null && !_completingLogin:
          _completingLogin = true;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _completePasswordLogin(value),
          );
        case AsyncError(:final error):
          showSnackBar(
            context,
            '${context.tr('Login Failed')}: ${_message(error)}',
            type: SnackBarType.error,
          );
        default:
          break;
      }
    });

    final loginState = ref.watch(loginProvider);
    final biometricAvailable = ref.watch(biometricAvailableProvider);
    final biometricEnabled = ref.watch(biometricEnabledProvider);
    final loading = loginState.isLoading;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 8,
              right: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: LanguageSelectorButton(
                    foregroundColor: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 72, 24, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Image.asset(
                          'assets/images/openimis-logo.png',
                          height: 96,
                          errorBuilder: (_, _, _) => Icon(
                            Icons.health_and_safety,
                            size: 72,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          context.tr('openIMIS Login'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.tr('Sign in with your openIMIS account'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 32),
                        AppTextField(
                          controller: _userNameController,
                          labelText: context.tr('User Name'),
                          hintText: context.tr('Enter username'),
                          prefixIcon: const Icon(Icons.person_outline),
                          textInputAction: TextInputAction.next,
                          enabled: !loading,
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? context.tr('Please enter a username')
                              : null,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _passwordController,
                          labelText: context.tr('Password'),
                          hintText: context.tr('Enter password'),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: context.tr('Show password'),
                            onPressed: loading
                                ? null
                                : () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          enabled: !loading,
                          validator: (value) => value == null || value.isEmpty
                              ? context.tr('Please enter a password')
                              : null,
                          onSubmitted: (_) => _handleLogin(),
                        ),
                        if (loginState.hasError)
                          AppErrorMessage(message: _message(loginState.error!)),
                        const SizedBox(height: 24),
                        AppButton(
                          expanded: true,
                          onPressed: _handleLogin,
                          isLoading: loading,
                          loadingLabel: context.tr('In Progress…'),
                          label: Text(context.tr('Login')),
                        ),
                        if (biometricAvailable.value == true &&
                            biometricEnabled.value == true) ...[
                          const SizedBox(height: 12),
                          AppButton(
                            expanded: true,
                            variant: AppButtonVariant.secondary,
                            onPressed: _authenticatingBiometric
                                ? null
                                : () => _tryBiometricLogin(),
                            isLoading: _authenticatingBiometric,
                            loadingLabel: context.tr('Authenticating…'),
                            icon: const Icon(Icons.fingerprint_rounded),
                            label: Text(context.tr('Use biometrics')),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          context.tr(
                            'Claim Administrator setup is requested only when you open a Claims feature.',
                          ),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(loginProvider.notifier)
        .login(
          LoginRequestModel(
            userName: _userNameController.text.trim(),
            password: _passwordController.text,
          ),
        );
  }

  Future<void> _completePasswordLogin(LoginResponseModel response) async {
    if (!mounted) return;
    await showAppFeedbackDialog(
      context: context,
      message: '${context.tr('Login Successful')}: ${response.userName}',
      type: AppFeedbackType.success,
    );

    final service = ref.read(biometricAuthServiceProvider);
    final alreadyEnabled = await service.isEnabled();
    final available = await service.isAvailable();
    if (!mounted) return;

    if (!alreadyEnabled && available) {
      await service.markSetupOffered();
      if (!mounted) return;
      final enable = await showAppBottomSheet<bool>(
        context: context,
        heightFactor: 0.5,
        builder: (sheetContext) => AppSheetContent(
          icon: Icon(
            Icons.fingerprint,
            size: 48,
            color: Theme.of(sheetContext).colorScheme.primary,
          ),
          title: Text(context.tr('Enable biometric login?')),
          content: Text(
            context.tr(
              'Use fingerprint or Face ID to securely access your saved session next time.',
            ),
          ),
          actions: [
            AppButton(
              variant: AppButtonVariant.text,
              onPressed: () => Navigator.pop(sheetContext, false),
              label: Text(context.tr('Not now')),
            ),
            AppButton(
              onPressed: () => Navigator.pop(sheetContext, true),
              label: Text(context.tr('Enable')),
            ),
          ],
        ),
      );
      if (enable == true && mounted) {
        final enabled = await ref
            .read(biometricEnabledProvider.notifier)
            .enable();
        if (!enabled && mounted) {
          await showAppFeedbackDialog(
            context: context,
            type: AppFeedbackType.error,
            message: context.tr('Biometric authentication was not enabled.'),
          );
        }
      }
    }
    if (mounted) context.router.replaceAll([const HomeWithTabsRoute()]);
  }

  Future<void> _tryBiometricLogin() async {
    if (_authenticatingBiometric) return;
    final enabled = await ref.read(biometricEnabledProvider.future);
    final sessionNotifier = ref.read(userSessionProvider.notifier);
    final hasSavedSession = await sessionNotifier.hasSavedSession();
    if (!mounted) return;
    if (!enabled || !hasSavedSession) {
      showAppFeedbackDialog(
        context: context,
        type: AppFeedbackType.info,
        message: context.tr(
          'Sign in with your username and password first, then enable biometric login.',
        ),
      );
      return;
    }

    setState(() => _authenticatingBiometric = true);
    final authenticated = await ref
        .read(biometricAuthServiceProvider)
        .authenticate();
    if (!mounted) return;
    setState(() => _authenticatingBiometric = false);
    if (authenticated) {
      final restored = await sessionNotifier.restoreSavedSession();
      if (!mounted) return;
      if (restored?.isAuthenticated == true) {
        _userNameController.text = restored!.username ?? '';
        context.router.replaceAll([const HomeWithTabsRoute()]);
      }
    } else {
      showSnackBar(
        context,
        context.tr(
          'Biometric authentication was cancelled or could not be verified.',
        ),
        type: SnackBarType.error,
      );
    }
  }

  static String _message(Object error) {
    if (error is FormatException) return error.message;
    return error.toString().replaceFirst('Exception: ', '');
  }
}
