import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openimis_claim_policy_app/core/localization/app_localizations.dart';
import 'package:openimis_claim_policy_app/feature/claims/repositories/claim_setup_repository.dart';
import 'package:openimis_claim_policy_app/feature/shared/widgets/app_widgets.dart';

class ClaimSetupSheet extends ConsumerStatefulWidget {
  const ClaimSetupSheet({
    super.key,
    this.initialCode,
    this.synchronizeOnOpen = false,
  });

  final String? initialCode;
  final bool synchronizeOnOpen;

  @override
  ConsumerState<ClaimSetupSheet> createState() => _ClaimSetupSheetState();
}

class _ClaimSetupSheetState extends ConsumerState<ClaimSetupSheet> {
  late final TextEditingController _codeController;
  String? _progress;
  String? _error;

  bool get _isLoading => _progress != null;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.initialCode ?? '');
    if (widget.synchronizeOnOpen && _codeController.text.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _continue());
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_codeController.text.trim().isEmpty) {
      setState(() => _error = context.tr('Please enter Claim Admin Code.'));
      return;
    }
    setState(() {
      _error = null;
      _progress = context.tr('Validating Claim Administrator…');
    });
    try {
      final result = await ref
          .read(claimSetupRepositoryProvider)
          .initialize(
            _codeController.text,
            onProgress: (message) {
              if (mounted) setState(() => _progress = message);
            },
          );
      if (!mounted) return;
      Navigator.pop(context, result);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _progress = null;
        _error = error is FormatException ? error.message : error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isLoading,
      child: AppSheetContent(
        icon: Icon(
          _isLoading ? Icons.sync : Icons.admin_panel_settings_outlined,
          size: 44,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          context.tr(_isLoading ? 'Checking for updates' : 'Claim Admin'),
        ),
        showCloseButton: !_isLoading,
        content: _isLoading
            ? Column(
                children: [
                  const AppLoadingIndicator(),
                  const SizedBox(height: 20),
                  Text(_progress!, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(
                    context.tr(
                      'Keep the app open while diagnoses, services, and items are synchronized.',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: _codeController,
                    labelText: context.tr('Claim Admin Code'),
                    hintText: context.tr('Enter code'),
                    prefixIcon: const Icon(Icons.badge_outlined),
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    autofocus: true,
                    onSubmitted: (_) => _continue(),
                  ),
                  if (_error != null) AppErrorMessage(message: _error!),
                ],
              ),
        actions: _isLoading
            ? const []
            : [
                AppButton(
                  variant: AppButtonVariant.text,
                  onPressed: () => Navigator.pop(context),
                  label: Text(context.tr('Cancel')),
                ),
                AppButton(
                  onPressed: _continue,
                  label: Text(context.tr('Continue')),
                ),
              ],
      ),
    );
  }
}
