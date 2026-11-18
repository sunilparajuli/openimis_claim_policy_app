# Understood CSU mobile features

This file tracks requirements that are clear enough to implement for the single
CSU Cameroon mobile application. The source of truth remains the Gherkin files
under `~/Downloads/features`; Redmine numbers are retained for traceability.

## Unified application

- One installation provides Claims, Policies CSU, and Policies HIV workflows.
- The signed-in user's rights, facility, officer identity, and available
  programs determine which workflows and records are available.
- The backend remains authoritative for authentication and authorization.

## Shared offline foundation

- Download `GET api/tools/extracts/download_master_data` as a ZIP containing
  `MasterData.txt`.
- Retain every documented section and consume only exposed frontend module
  configuration.
- Cache master data locally and allow offline startup from the cached bundle.
- Persist offline claims and policy/enrolment work with individual sync states.

## Localization and identifiers

- French phone locale selects French; English selects English; unsupported
  locales fall back to English. Dates are displayed as `dd/MM/yyyy`.
- Normalize surrounding whitespace and ignorable characters from MPI/CHFID
  values before validation and submission.
- Reject invisible characters embedded inside an MPI/CHFID.
- Support manual entry and scanning of valid insuree QR codes.

## Claims

- A claim belongs to one downloaded program and uses valid local diagnoses.
- Services and items use the facility price list and are filtered for the
  facility, including records with no facility.
- Prices are read-only and quantities are positive.
- Claims can be saved offline and synchronized with source `MOB`.
- The XML export path creates the legacy password-protected claim archive using
  the build-config password.

## Policies CSU and HIV

- Persist family, insuree, policy, and relevant contribution changes offline.
- Apply downloaded product minimum/maximum ages; zero means no limit.
- HIV enrolment applies HIV-specific MPI and patient rules.
- Chèque Santé policies require pregnancy week 1–42 and a usable cheque; a
  successful attribution changes a `New` cheque to `Used`.

## Error behavior

- Display localized, actionable validation messages and a generic localized
  server message for unexpected backend errors.
- Keep success, rejection, duplicate, and transport/server failure outcomes
  separate during synchronization.
- Report non-sensitive errors to GlitchTip with release and workflow context.
