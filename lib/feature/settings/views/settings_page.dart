import 'package:openimis_claim_policy_app/feature/shared/widgets/app_widgets.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:openimis_claim_policy_app/core/localization/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openimis_claim_policy_app/my_app.dart' show themeModeProvider;
import 'package:openimis_claim_policy_app/feature/shared/navigation/app_router.gr.dart';
import 'package:openimis_claim_policy_app/feature/shared/providers/user_session_provider.dart';
import 'package:openimis_claim_policy_app/feature/shared/utils/ui_utils.dart';
import 'permissions_page.dart';
import 'package:openimis_claim_policy_app/core/config/currency_provider.dart';
import 'package:openimis_claim_policy_app/core/config/claim_form_requirements_provider.dart';
import 'package:openimis_claim_policy_app/core/auth/biometric_auth_service.dart';

@RoutePage()
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final currency = ref.watch(currencyProvider);
    final biometricEnabled = ref.watch(biometricEnabledProvider);
    final claimRequirements = ref.watch(claimFormRequirementsProvider);
    final session = ref.watch(userSessionProvider).value;

    return Scaffold(
      appBar: AppAppBar(title: Text(context.tr('Settings'))),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppDropdownField<String>(
              key: ValueKey(currency.value),
              value: currency.value ?? 'USD',
              isExpanded: true,
              decoration: InputDecoration(
                labelText: context.tr('Currency'),
                helperText: context.tr(
                  'Display currency only; amounts are not converted.',
                ),
              ),
              items: currencies.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text('${entry.key} — ${context.tr(entry.value)}'),
                    ),
                  )
                  .toList(),
              onChanged: currency.isLoading
                  ? null
                  : (code) async {
                      if (code == null) return;
                      try {
                        await ref.read(currencyProvider.notifier).select(code);
                      } catch (_) {
                        if (context.mounted) {
                          showAppFeedbackSheet(
                            context: context,
                            type: AppFeedbackType.error,
                            message: context.tr(
                              'Unable to save currency. Please try again.',
                            ),
                          );
                        }
                      }
                    },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.security_outlined),
            title: Text(context.tr('Permissions')),
            subtitle: Text(context.tr('Camera, photos and location')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const PermissionsPage()),
            ),
          ),
          AppSectionHeader(title: context.tr('Claims Configuration')),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Icon(
                Icons.admin_panel_settings_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(context.tr('Claim Administrator')),
              subtitle: Text(
                session?.claimAdminCode?.isNotEmpty == true
                    ? '${session!.claimAdminCode}${session.claimAdminName?.isNotEmpty == true ? ' — ${session.claimAdminName}' : ''}'
                    : context.tr('Not configured'),
              ),
              trailing: session?.claimAdminCode?.isNotEmpty == true
                  ? IconButton(
                      tooltip: context.tr('Clear Claim Administrator'),
                      onPressed: () => _showClearClaimAdminSheet(context, ref),
                      icon: const Icon(Icons.delete_outline_rounded),
                    )
                  : null,
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ExpansionTile(
              leading: Icon(
                Icons.rule_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(context.tr('Claim Form Requirements')),
              subtitle: Text(
                context.tr('Choose additional mandatory claim fields'),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    context.tr(
                      'Core fields required by openIMIS cannot be disabled.',
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                _requirementSwitch(
                  context: context,
                  title: context.tr('Guarantee Number'),
                  icon: Icons.security_outlined,
                  value: claimRequirements.value?.guaranteeNumber ?? false,
                  enabled: !claimRequirements.isLoading,
                  onChanged: (value) => ref
                      .read(claimFormRequirementsProvider.notifier)
                      .save(
                        (claimRequirements.value ??
                                const ClaimFormRequirements())
                            .copyWith(guaranteeNumber: value),
                      ),
                ),
                _requirementSwitch(
                  context: context,
                  title: context.tr('Secondary Diagnosis'),
                  icon: Icons.medical_information_outlined,
                  value: claimRequirements.value?.secondaryDiagnosis ?? false,
                  enabled: !claimRequirements.isLoading,
                  onChanged: (value) => ref
                      .read(claimFormRequirementsProvider.notifier)
                      .save(
                        (claimRequirements.value ??
                                const ClaimFormRequirements())
                            .copyWith(secondaryDiagnosis: value),
                      ),
                ),
                _requirementSwitch(
                  context: context,
                  title: context.tr('Medical Service'),
                  icon: Icons.medical_services_outlined,
                  value: claimRequirements.value?.medicalService ?? false,
                  enabled: !claimRequirements.isLoading,
                  onChanged: (value) => ref
                      .read(claimFormRequirementsProvider.notifier)
                      .save(
                        (claimRequirements.value ??
                                const ClaimFormRequirements())
                            .copyWith(medicalService: value),
                      ),
                ),
                _requirementSwitch(
                  context: context,
                  title: context.tr('Medical Item'),
                  icon: Icons.medication_outlined,
                  value: claimRequirements.value?.medicalItem ?? false,
                  enabled: !claimRequirements.isLoading,
                  onChanged: (value) => ref
                      .read(claimFormRequirementsProvider.notifier)
                      .save(
                        (claimRequirements.value ??
                                const ClaimFormRequirements())
                            .copyWith(medicalItem: value),
                      ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          AppSectionHeader(title: context.tr('Security')),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SwitchListTile(
              value: biometricEnabled.value ?? false,
              onChanged: biometricEnabled.isLoading
                  ? null
                  : (enable) async {
                      if (!enable) {
                        await ref
                            .read(biometricEnabledProvider.notifier)
                            .disable();
                        return;
                      }
                      final enabled = await ref
                          .read(biometricEnabledProvider.notifier)
                          .enable();
                      if (!enabled && context.mounted) {
                        showSnackBar(
                          context,
                          context.tr(
                            'Biometrics are unavailable or authentication was cancelled.',
                          ),
                          type: SnackBarType.error,
                        );
                      }
                    },
              title: Text(context.tr('Biometric Login')),
              subtitle: Text(
                biometricEnabled.value == true
                    ? context.tr('Enabled')
                    : context.tr('Disabled'),
              ),
              secondary: Icon(
                Icons.fingerprint,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Icon(
                Icons.logout_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(context.tr('Logout')),
              subtitle: Text(context.tr('Sign out of your openIMIS account')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLogoutSheet(context, ref),
            ),
          ),
          // Theme Section
          Semantics(
            identifier: 'settings_appearance_header',
            header: true,
            label: context.tr('Appearance'),
            child: AppSectionHeader(title: context.tr('Appearance')),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                SwitchListTile(
                  value: isDark,
                  onChanged: (value) {
                    ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                  },
                  title: Text(context.tr('Dark Mode')),
                  subtitle: Text(
                    isDark ? context.tr('Enabled') : context.tr('Disabled'),
                  ),
                  secondary: Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          // Help & Support Section
          AppSectionHeader(title: context.tr('Help & Support')),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.help_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(context.tr('Help Center')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.router.push(
                      CommonWebviewRoute(
                        title: context.tr('Help Center'),
                        url: 'https://www.google.com',
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.contact_support_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(context.tr('Contact Support')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.router.push(
                      CommonWebviewRoute(
                        title: context.tr('Contact Support'),
                        url: 'https://www.google.com',
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // About Section
          AppSectionHeader(title: context.tr('About')),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.privacy_tip_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(context.tr('Privacy Policy')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.router.push(
                      CommonWebviewRoute(
                        title: context.tr('Privacy Policy'),
                        url: 'https://www.google.com',
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.description_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(context.tr('Terms of Service')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.router.push(
                      CommonWebviewRoute(
                        title: context.tr('Terms of Service'),
                        url: 'https://www.google.com',
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Danger Zone Section
          AppSectionHeader(title: context.tr('Danger Zone')),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(
              context,
            ).colorScheme.errorContainer.withValues(alpha: 0.3),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.delete_forever_outlined,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    context.tr('Delete Account'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    context.tr('Permanently delete your account and data'),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  onTap: () => _showDeleteAccountDialog(context, ref),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _requirementSwitch({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool value,
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) => SwitchListTile(
    value: value,
    onChanged: enabled ? onChanged : null,
    title: Text(title),
    subtitle: Text(context.tr(value ? 'Mandatory' : 'Optional')),
    secondary: Icon(icon, color: Theme.of(context).colorScheme.primary),
  );

  void _showLogoutSheet(BuildContext context, WidgetRef ref) {
    showAppBottomSheet(
      context: context,
      heightFactor: 0.5,
      builder: (sheetContext) => AppSheetContent(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(sheetContext).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.security_rounded,
                color: Theme.of(sheetContext).colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(context.tr('Secure Logout'))),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(sheetContext).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                color: Theme.of(sheetContext).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Are you sure you want to logout?'),
                      style: Theme.of(sheetContext).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.tr(
                        'Your saved session will be removed from this device. You can sign in again at any time.',
                      ),
                      style: Theme.of(sheetContext).textTheme.bodyMedium
                          ?.copyWith(
                            color: Theme.of(
                              sheetContext,
                            ).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          AppButton(
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.pop(sheetContext),
            label: Text(context.tr('Cancel')),
          ),
          AppButton(
            onPressed: () async {
              Navigator.pop(sheetContext);
              await ref.read(userSessionProvider.notifier).logout();
              ref.read(biometricEnabledProvider.notifier).reset();
              if (context.mounted) {
                context.router.replaceAll([LoginRoute(title: 'Login')]);
              }
            },
            style: AppButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.logout_rounded, size: 18),
                const SizedBox(width: 8),
                Text(context.tr('Logout')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showClearClaimAdminSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showAppConfirmationSheet(
      context: context,
      title: context.tr('Clear Claim Administrator?'),
      message: context.tr(
        'The saved Claim Administrator code and facility will be removed. You will be asked for the code when opening a Claims feature again.',
      ),
      confirmLabel: context.tr('Clear'),
      cancelLabel: context.tr('Cancel'),
      icon: Icons.admin_panel_settings_outlined,
      destructive: true,
    );
    if (confirmed != true) return;
    await ref.read(userSessionProvider.notifier).clearClaimAdministrator();
    if (context.mounted) {
      showSnackBar(
        context,
        context.tr('Claim Administrator cleared'),
        type: SnackBarType.success,
      );
    }
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showAppBottomSheet(
      context: context,
      builder: (context) => AppSheetContent(
        title: Row(
          children: [
            Icon(
              Icons.warning_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
            Text(context.tr('Delete Account')),
          ],
        ),
        content: Text(
          context.tr(
            'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
          ),
        ),
        actions: [
          AppButton(
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('No, Cancel')),
          ),
          AppButton(
            variant: AppButtonVariant.primary,
            onPressed: () {
              Navigator.pop(context);
              _handleDeleteAccount(context, ref);
            },
            style: AppButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: Text(context.tr('Yes, Delete')),
          ),
        ],
      ),
    );
  }

  void _handleDeleteAccount(BuildContext context, WidgetRef ref) {
    // TODO: Implement actual account deletion logic
    // TODO: Call API to delete account
    // TODO: Clear local data and preferences
    // TODO: Logout user and navigate to login screen

    // Clear the current user session.
    ref.read(userSessionProvider.notifier).logout();

    showSnackBar(
      context,
      context.tr('Account deleted successfully'),
      type: SnackBarType.success,
    );

    // Navigate to login after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        context.router.replaceAll([LoginRoute(title: 'Login')]);
      }
    });
  }
}
