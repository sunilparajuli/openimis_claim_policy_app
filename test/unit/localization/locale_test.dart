import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openimis_claim_policy_app/core/localization/app_localizations.dart';
import 'package:openimis_claim_policy_app/core/localization/locale_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLocalizations Tests', () {
    test('Default English strings match expectations', () {
      final l10n = AppLocalizations(const Locale('en'));

      expect(l10n.isFrench, false);
      expect(l10n.appTitle, 'openIMIS Healthcare');
      expect(l10n.welcomeBack, 'Welcome Back!');
      expect(l10n.insureeVerificationTitle, 'Insuree Verification & Policy');
      expect(l10n.newClaimFormTitle, 'New Claim Form');
      expect(l10n.policyRenewalTitle, 'Policy Renewal Form');
      expect(l10n.submitFhirClaim, 'Post Claim');
      expect(l10n.chfIdLabel, 'Insurance No');
    });

    test('French localized strings match expectations', () {
      final l10n = AppLocalizations(const Locale('fr'));

      expect(l10n.isFrench, true);
      expect(l10n.appTitle, 'openIMIS Santé');
      expect(l10n.welcomeBack, 'Bienvenue !');
      expect(l10n.insureeVerificationTitle, 'Vérification Assuré & Police');
      expect(l10n.newClaimFormTitle, 'Formulaire de Réclamation (FHIR)');
      expect(l10n.policyRenewalTitle, 'Renouvellement de Police');
      expect(l10n.submitFhirClaim, 'Enregistrer la réclamation');
      expect(l10n.chfIdLabel, 'Numéro d’assurance');
      expect(l10n.diagnoses, 'Diagnostic');
    });
  });

  group('AppLocaleNotifier Riverpod Tests', () {
    test('Default locale is English and can be changed/toggled', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Verify default is 'en'
      expect(container.read(appLocaleProvider), const Locale('en'));

      // Switch to French
      container.read(appLocaleProvider.notifier).setLocale(const Locale('fr'));
      expect(container.read(appLocaleProvider), const Locale('fr'));

      // Toggle back to English
      container.read(appLocaleProvider.notifier).toggleLanguage();
      expect(container.read(appLocaleProvider), const Locale('en'));

      // Toggle again to French
      container.read(appLocaleProvider.notifier).toggleLanguage();
      expect(container.read(appLocaleProvider), const Locale('fr'));
    });
  });
}
