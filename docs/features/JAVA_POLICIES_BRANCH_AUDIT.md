# Java Policies application branch audit

This document is a reference audit of
[`openimis/policies_android_app_java`](https://github.com/openimis/policies_android_app_java).
It is intentionally separate from `ADDED_FEATURES.md`: these are findings from
another application, not features delivered in the Flutter application.

Audit date: 2026-11-11

## 2026-11-16 mngoe CSU addendum

The original audit covered the upstream `openimis` repository and must not be
read as an audit of the client's fork. The client fork has subsequently been
verified directly:

- `mngoe/policies_android_app_java` `main-csu` implements CSU family, insuree,
  policy and pregnancy-age GraphQL payloads.
- `main-csu-vih` and `feat-34496-vih` implement a distinct HIV flow, including
  the HIV marker email and asynchronous mutation polling.
- The fork polls `MutationLog` numeric status (`0` received, `1` error, `2`
  success), then re-queries a family by the head MPI to obtain the database ID.
- The mngoe CSU tools exporter sends product `program` as a numeric programme
  ID plus `minAge`/`maxAge`; the app must resolve it through the downloaded
  `programs` section.

These branches are now the API/behavior reference for the Flutter CSU/HIV
implementation. The upstream findings below remain useful only for generic
Policies behavior.

## Result for the requested branch

### `mngoe-patch-1`

- Tip: `fb0a41c` (`Update README.md`, 2024-07-22).
- This branch is already an ancestor of the current `develop` branch.
- It has no branch-only product implementation to port.
- Its application snapshot contains the generic Policies application:
  family and insuree enrolment, policies, premiums, renewals, enquiry,
  feedback, reporting, offline SQLite data, XML exports, photos, GraphQL
  uploads, and master-data download/import.
- Its master-data importer consumes the older core sections but not
  `programs`, `cheques`, or `ModuleConfiguration`.
- Its policy and insuree GraphQL inputs contain no HIV/TARV, programme,
  pregnancy-age, or Chèque Santé fields.
- Chèque-related resource strings exist but have no corresponding workflow.
- The bundled libraries are jQuery 3.2.1 and jQuery UI 1.12.1, below the CSU
  specification's requested versions.

Conclusion: use this branch only as a reference for generic Policies behavior.
It is not a CSU or HIV implementation.

## Other live branches

### `develop`

This is the current integration branch and the best Java reference for the
modern generic Policies workflow. Later work includes:

- refreshed family, insuree, policy, premium, contribution, and enrolment UI;
- GraphQL/Django session and CSRF handling;
- family download and progress handling;
- master-data download fixes;
- GlitchTip/Sentry configuration;
- system-locale startup behavior;
- enrolment and enquiry test coverage.

It still contains no dedicated HIV/VIH/TARV, pregnancy-week, Chèque Santé, or
temporary-to-final MPI workflow found by the audit.

### `feature-34418`

Adds a signature screen and supporting visual/input changes. This can be a
future reference if CSU requires handwritten consent, but signature capture is
not part of the supplied consolidated specification.

### `feature/OP-2038`

Contains extensive family and insuree editing work, including form, database,
GraphQL, and policy/premium changes. Its useful behavior has since evolved on
`develop`; port behavior from `develop` rather than copying this older branch.

### `implementation/COM/develop`

Adds polygamous families, subfamilies, and sub-insuree screens. This is a
Comoros customization and is not part of the stated Cameroon CSU scope.

### `implementation/MRT/main`

Adds attachments, QR-scanner adjustments, and changes to mandatory fields for
the Mauritania implementation. QR handling may be useful as a reference, but
its country-specific field rules must not be copied into CSU validation.

### `impl/gambia` and `feat/OIG-144_gambia_mobile_app_customization`

Contain Gambia-specific enrolment and renewal customization. Notably, they use
a combined `MobileEnrolmentGraphQLRequest`, which is useful as an architectural
reference for synchronizing a complete offline enrolment. Product rules and
field requirements are country-specific.

### `impl/niger23` and `niger_updates`

Contain Niger-specific configuration, locales, URLs, and the same combined
mobile-enrolment pattern. They do not provide Cameroon HIV or Chèque Santé
logic.

### `implementation/chf/main`

An older CHF/Tanzania implementation branch. It is not a suitable base for the
new unified CSU application.

### Maintenance branches

`chore/fix-failing-tests`, `fix/failing-tests-in-ci`, `feedback_fix`, and
`fix-OP-1602` contain narrow maintenance fixes rather than CSU functionality.

## Deleted or merged branch evidence

The repository history contains a merged PR named `mngoe/csu-to-merge` at
commit `47af614`. Despite the name, the PR changes only the About page and adds
an app-version bridge method. It does not contain CSU enrolment functionality.

The current history also contains generic master-data, enrolment, login,
family, policy, contribution, localization, and error-reporting improvements.
No reachable commit matched the consolidated specification's HIV/TARV,
pregnancy-age, Chèque Santé product-selection, or temporary MPI requirements.

## Porting decision

Use Java `develop` as a behavioral reference for:

1. family and insuree create/edit flows;
2. policy, premium, contribution, and renewal flows;
3. offline enrolment persistence and complete-enrolment synchronization;
4. photo/QR handling;
5. master-data download recovery and progress UI;
6. session/CSRF handling and error reporting.

Implement these CSU requirements directly from the consolidated specification,
because none of the audited Java branches supplies them:

- distinct Policies CSU and Policies HIV modes;
- TARV/HIV fields and all-numeric HIV MPI rejection;
- programme-aware product selection;
- Chèque Santé number/status validation;
- mandatory pregnancy week and synchronized pregnancy age;
- pregnancy-age-dependent Chèque Santé products;
- temporary-to-final MPI linking;
- server-driven MPI and cheque-length configuration;
- all new master-data sections and exposed frontend configuration.
