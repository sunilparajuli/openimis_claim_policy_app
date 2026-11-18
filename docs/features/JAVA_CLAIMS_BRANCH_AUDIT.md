# Java Claims application branch audit

This document audits
[`openimis/claims_android_app_java`](https://github.com/openimis/claims_android_app_java)
as a reference for the unified Flutter application. It does not record Flutter
features as delivered.

Audit date: 2026-11-11

## Overall result

The Java Claims repository is a strong behavioral and data-flow reference. Its
current `develop` history includes real Cameroon work, notably the Cameroon
Voucher Scheme implementation at commit `297b5a0` (`OP-1199`). It must not be
ported blindly: several open requirements in the consolidated CSU
specification remain absent, and some legacy behavior directly conflicts with
the new contract.

## Useful functionality on `develop`

### Claim lifecycle

- Claim creation, editing, deletion, restoration, review, and local storage.
- Entered, accepted, rejected, exported, error, and archived upload states.
- Online FHIR claim submission with per-claim success, rejection, and backend
  error messages.
- Insuree enquiry and remote claim search.
- Offline XML export with one XML file per claim in a password-protected ZIP.

### Cameroon complex products

Commit `297b5a0`, titled `Cameroon Voucher Scheme for subservices and
subItems`, adds:

- complex/package services;
- service-to-subservice and service-to-item relations;
- quantity and price handling for package components;
- GraphQL pagination for medical services and items;
- manual-price configuration;
- complex-product XML export;
- local database tables for subservices and subitems.

This is directly useful when implementing the Cameroon service/item entry
model in Flutter. It is not the pregnancy/cheque Chèque Santé policy workflow.

### Facility-specific catalog and prices

Later `develop` work:

- resolves the logged-in claim administrator's health facility and price-list
  UUIDs;
- downloads services and items from those price lists;
- stores health-facility prices and mapping locally;
- paginates large service/item downloads;
- reports missing price lists and partially skipped medication pages.

This is the closest Java reference for the specification's health-facility
catalog filtering and the 30,000-record performance case.

### Validation and configuration

- Module configuration is fetched through GraphQL and stored locally.
- The claim form applies configured field constraints.
- Invalid diagnosis codes are blocked by later fixes.
- Alphanumeric insuree numbers are supported by later fixes.
- Claim form behavior was adapted to claim module configuration in 2026.

The implementation does not consume the complete CSU `MasterData.txt`
contract, so the Flutter master-data model remains the source of truth.

### Robustness

- Sentry/GlitchTip integration and exception capture.
- Django session and CSRF handling.
- Unit coverage for claim save, synchronization, catalogue mapping, enquiry,
  and paginated/partial downloads.
- Startup language aligned to the phone locale.

## Specification coverage and gaps

### Present or useful reference

- Claims can be entered offline and synchronized.
- Health-facility price lists are used for services and items.
- Large catalogues are paginated and persisted locally.
- Invalid diagnosis codes are rejected.
- XML claim files are exported in a protected ZIP.
- Claim upload results are tracked per claim.
- Errors are sent to Sentry/GlitchTip.
- French and English localization behavior exists.

### Missing or not demonstrated

- No claim programme selector.
- No filtering of claim services by the selected programme.
- No Chèque Santé cheque-number field or validation.
- No Chèque Santé claim pregnancy-age handling.
- No explicit handling for an unattributed cheque.
- No user selection of pending claims to upload.
- No "select all" pending-claim action.
- Upload always reads every pending claim from the database.
- No dedicated transport tariff entry.
- No demonstrated temporary-to-final MPI lookup.
- No clear explicit `source = MOB` field in the FHIR payload.
- No dedicated duplicate-claim message mapping was found.

### Conflicting legacy behavior

- The Settings menu remains visible.
- Settings allow the archive password to be changed by the user.
- XML export reads the stored/user-selected password instead of always using
  only the build-config password.
- `MasterDataService.handleDownloadMasterData()` remains unimplemented; the app
  primarily refreshes diagnoses/services/items/configuration through separate
  APIs rather than the consolidated CSU master-data ZIP contract.
- Generic synchronization failures can still be presented as server errors;
  the new Flutter flow must distinguish successful uploads from refresh or
  follow-up failures.

## Other live branches

### `impl/gambia` and `feat/OIG-144_gambia_mobile_app_customization`

Country-specific login, catalogue, claim, payment, and synchronization changes.
`impl/gambia` refreshes all reference data. These are useful for comparison but
must not define Cameroon field rules.

### `impl/niger23`

Closely follows the Gambia customization with Niger configuration and URL
changes. It contains no additional CSU programme, cheque, or pregnancy logic.

### `release/2.2.0` and `main`

Older release baselines. They lack the later Cameroon complex-product,
facility-price-list, configuration, validation, and robustness improvements.

### `implementation/chf/main`

Older CHF/Tanzania implementation. Useful only for historical behavior and
localization comparison.

### Maintenance branches

`fix-fetchclaims-tests`, `fix/ci-test-failures`, `fix/various_fixes`, and
`small-improvements` contain test, CI, translation, and narrow maintenance
changes rather than new CSU behavior.

### `copymaster9`

An old 2019 branch and not a suitable implementation reference.

## Misleading CSU branch name

As in the Policies repository, the merged Claims PR named `mngoe/csu-to-merge`
does not contain a hidden CSU workflow. Merge commit `9117712` only adds the app
version to the About screen.

The actual Cameroon-specific Claims implementation is commit `297b5a0`, not
the `csu-to-merge` PR.

## Porting decision

Use Java Claims `develop` as a reference for:

1. local claim lifecycle and upload-state tracking;
2. FHIR claim construction and per-claim response processing;
3. facility price-list lookup and large paginated catalogues;
4. complex services with subservices and subitems;
5. offline claim XML construction and ZIP export structure;
6. claim validation, enquiry, session handling, and error reporting.

Implement these directly from the consolidated CSU specification instead of
copying Java behavior:

- programme selection and programme-aware catalog filtering;
- Chèque Santé claim rules;
- selectable pending claims and select-all upload;
- build-password-only XML archives and hidden Settings;
- explicit `MOB` source contract;
- duplicate-claim-specific messaging;
- transport tariff entry;
- consolidated master-data ZIP handling and server-driven mobile settings.
