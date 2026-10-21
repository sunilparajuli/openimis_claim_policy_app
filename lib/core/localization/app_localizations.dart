import 'package:flutter/widgets.dart';
import 'ui_translations.dart';

/// Provides bilingual localized strings (English and French) for the openIMIS app.
///
/// Default language is English ('en').
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get isFrench => locale.languageCode == 'fr';

  String translate(String english) =>
      isFrench ? frenchUiTranslations[english] ?? english : english;

  // Common
  String get appTitle => isFrench ? 'openIMIS Santé' : 'openIMIS Healthcare';
  String get welcomeBack => isFrench ? 'Bienvenue !' : 'Welcome Back!';
  String get welcomeSubtitle => isFrench
      ? 'Couverture Santé Universelle • Prestations & Polices'
      : 'Universal Health Coverage • Claims & Policies';
  String get submit => isFrench ? 'Soumettre' : 'Submit';
  String get cancel => isFrench ? 'Annuler' : 'Cancel';
  String get back => isFrench ? 'Retour' : 'Back';
  String get continueBtn => isFrench ? 'Continuer' : 'Continue';
  String get done => isFrench ? 'Terminé' : 'Done';
  String get search => isFrench ? 'Rechercher' : 'Search';
  String get verify => isFrench ? 'Vérifier' : 'Verify';
  String get language => isFrench ? 'Langue' : 'Language';
  String get english => 'English';
  String get french => 'Français';

  // Insuree Verification
  String get insureeVerificationTitle => isFrench
      ? 'Vérification Assuré & Police'
      : 'Insuree Verification & Policy';
  String get searchInsureeTitle =>
      isFrench ? 'Rechercher un assuré par N° CHF' : 'Search Insuree by CHF ID';
  String get chfIdLabel =>
      isFrench ? 'Identifiant CHF / N° Carte' : 'CHF ID / Card Number';
  String get simulateQrScan =>
      isFrench ? 'Scanner Code QR' : 'Simulate QR Scan';
  String get policyStatus => isFrench ? 'Statut de la Police' : 'Policy Status';
  String get active => isFrench ? 'ACTIF' : 'ACTIVE';
  String get expired => isFrench ? 'EXPIRÉ' : 'EXPIRED';
  String get suspended => isFrench ? 'SUSPENDU' : 'SUSPENDED';
  String get validUntil => isFrench ? 'Valide jusqu\'au :' : 'Valid Until:';
  String get benefitBalances => isFrench
      ? 'Plafonds de prestations & Soldes'
      : 'Benefit Balances & Limits';
  String get opCeiling => isFrench ? 'Plafond Ambulatoire (OP)' : 'OP Ceiling';
  String get ipCeiling =>
      isFrench ? 'Plafond Hospitalisation (IP)' : 'IP Ceiling';
  String get visitsLeft => isFrench ? 'Visites Restantes' : 'Visits Left';
  String get consultationsLeft =>
      isFrench ? 'Consultations Restantes' : 'Consultations';
  String get startClaimForInsuree => isFrench
      ? 'Créer une Réclamation pour cet Assuré'
      : 'Start New Claim for this Insuree';

  // Claim Wizard
  String get newClaimFormTitle =>
      isFrench ? 'Formulaire de Réclamation (FHIR)' : 'New Claim Form';
  String get visitAndFacility =>
      isFrench ? 'Établissement & Visite' : 'Visit & Facility Details';
  String get healthFacility =>
      isFrench ? 'Formation Sanitaire' : 'Health Facility';
  String get claimCode =>
      isFrench ? 'Numéro de Réclamation' : 'Claim Code / Number';
  String get claimAdminDoctor =>
      isFrench ? 'Agent / Médecin Traitant' : 'Claim Administrator / Doctor';
  String get visitType => isFrench ? 'Type de Visite' : 'Visit Type';
  String get visitEmergency => isFrench ? 'Urgence' : 'Emergency';
  String get visitReferral => isFrench ? 'Référé' : 'Referral';
  String get visitOther => isFrench ? 'Autre' : 'Other';
  String get guaranteeNumber => isFrench
      ? 'Numéro de Prise en Charge (Optionnel)'
      : 'Guarantee Number (Optional)';
  String get diagnoses =>
      isFrench ? 'Diagnostics (CIM-10)' : 'Diagnoses (ICD-10)';
  String get primaryDiagnosis => isFrench
      ? 'Diagnostic Principal (Obligatoire)'
      : 'Primary Diagnosis (Mandatory)';
  String get secondaryDiagnoses => isFrench
      ? 'Diagnostics Secondaires (Optionnel)'
      : 'Secondary Diagnoses (Optional)';
  String get addSecondaryDiagnosis =>
      isFrench ? 'Ajouter un Diagnostic Secondaire' : 'Add Secondary Diagnosis';
  String get medicalServices =>
      isFrench ? 'Prestations Médicales' : 'Medical Services';
  String get addMedicalService =>
      isFrench ? 'Ajouter une Prestation' : 'Add Medical Service';
  String get medicationsAndItems =>
      isFrench ? 'Médicaments & Consommables' : 'Medications & Items';
  String get addMedication =>
      isFrench ? 'Ajouter un Médicament / Article' : 'Add Medication / Item';
  String get reviewAndAdjudication =>
      isFrench ? 'Révision & Soumission' : 'Review & Adjudication';
  String get totalClaimAmount =>
      isFrench ? 'Montant Total Réclamé' : 'Total Claim Amount';
  String get submitFhirClaim =>
      isFrench ? 'Soumettre la Réclamation (FHIR)' : 'Submit FHIR Claim';

  // Policy Renewal
  String get policyRenewalTitle =>
      isFrench ? 'Renouvellement de Police' : 'Policy Renewal Form';
  String get insureeIdentification => isFrench
      ? 'Identification de l\'Assuré'
      : 'Insuree & Policy Identification';
  String get insurancePlan =>
      isFrench ? 'Régime d\'Assurance Maladie' : 'Health Insurance Plan';
  String get paymentDetails =>
      isFrench ? 'Paiement & Quittance' : 'Payment & Receipt Details';
  String get payerType => isFrench ? 'Type de Payeur' : 'Payer Type';
  String get payerSelf =>
      isFrench ? 'Assuré / Ménage' : 'Self (Individual / Household)';
  String get payerGov =>
      isFrench ? 'Subvention Publique' : 'Government Subsidy';
  String get payerDonor => isFrench ? 'Donateur / ONG' : 'Donor / NGO Grant';
  String get receiptNumber => isFrench
      ? 'Numéro de Reçu Bancaire / Mobile Money'
      : 'Bank / Mobile Money Receipt Number';
  String get calculatedPremium =>
      isFrench ? 'Prime Calculée :' : 'Calculated Premium:';
  String get confirmRenewal => isFrench
      ? 'Confirmer le Renouvellement'
      : 'Confirm & Submit Policy Renewal';
}

extension LocalizedUi on BuildContext {
  String tr(String english) => AppLocalizations.of(this).translate(english);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'fr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return Future.value(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
