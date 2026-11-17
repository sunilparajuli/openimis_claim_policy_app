# Added CSU features

This is the implementation ledger for branch `csu-unified-app`.

## Implemented

### CSU master-data foundation (`a24bbcf`)

- Authenticated ZIP download from the documented tools endpoint.
- `MasterData.txt` extraction and JSON parsing outside the UI isolate.
- Validation of all documented top-level master-data sections.
- Preservation of backend-owned record fields.
- Product, program, cheque, and exposed frontend configuration accessors.
- Atomic local caching of the source ZIP for offline reload.

### Phone locale and MPI normalization

- App startup selects French for a French phone and English otherwise.
- Runtime phone-locale changes update the app locale.
- Shared MPI/CHFID normalization removes surrounding whitespace and ignorable
  characters while rejecting embedded invisible characters.
- Existing claim, insuree enquiry, policy renewal, and family-member entry paths
  use the shared normalization behavior.

### Unified CSU workspace and synchronization

- Master data refresh starts when the authenticated home shell opens.
- A cached ZIP remains usable when the refresh cannot reach the backend.
- The home screen shows last synchronization time and product, program, and
  health-facility counts.
- Claims, Policies CSU, and Policies HIV cards are derived from downloaded
  controls and program data. Existing Claims and CSU enrolment flows are
  linked directly; the dedicated HIV form remains a subsequent slice.
- Demo mode serves a valid CSU master-data archive so this workspace is visible
  during local development.

### Claims CSU contract

- Claims use the mngoe CSU `createClaim` GraphQL contract with programme IDs,
  backend entity IDs, and source `MOB`.
- A programme is mandatory and filters services/items by programme and health
  facility, while retaining catalogue entries assigned to no facility.
- The full claim catalogue is persisted atomically after setup and restored for
  the same Claim Admin when the backend is unavailable. Encoding and decoding
  run outside the UI isolate and retain programme metadata for 30,000-service
  and 30,000-item catalogues.
- Offline claims can be selected individually or with Select All before upload.
- Claim creation now waits for numeric MutationLog completion before marking a
  record uploaded. Duplicate and other mutation failures are labelled as claim
  errors, preserve backend detail, and remain visible/retryable offline.
- Selected claims can be exported as one legacy-compatible XML file per claim
  inside an AES-256 protected ZIP. The password is build-only through
  `CLAIMS_ARCHIVE_PASSWORD`; the app refuses to create an unprotected archive.
- The protected archive is handed to the native Android/iOS share sheet and
  exported records receive the legacy `Exported` status.

### Enquiry and operational diagnostics

- A camera-backed QR scanner accepts the raw MPI/CHFID format used by the Java
  apps, normalizes safe boundary characters, rejects ambiguous embedded
  characters, and starts enquiry automatically.
- Production builds support GlitchTip through the Sentry-compatible SDK using
  `GLITCHTIP_DSN`, with package version/build release, environment, unified-app
  tag, workflow tags for explicit captures, and default PII disabled.

### CSU/HIV policy enrolment

- Typed family-head, insuree, and policy inputs now match the mngoe
  `createFamily`, `createInsuree`, and `createPolicy` GraphQL contracts.
- HIV enrolments carry the legacy backend marker and reject an all-numeric MPI
  locally with the backend translation key.
- Chèque Santé policy inputs enforce pregnancy week 1–42 and transmit it as
  `pregnancyAge`.
- Product `minAge`/`maxAge` rules are validated locally, including expiry at
  the limiting birthday and the documented zero-means-unlimited behavior.
- CSU and HIV now open distinct master-data-backed forms. The forms enforce
  server input limits, product age rules, and Chèque Santé fields before saving
  to a persistent SQLite queue.
- The enrolment screen reloads queued work after restart and synchronizes in
  family → members → policies order while polling mutation status.
- Downloaded cheque records are checked with case-sensitive New/Used status;
  unknown and Used cheques show the specified messages before offline save.
- HTTP server failures use the specified generic translated message without
  replacing specific GraphQL/business validation messages.
- Family dependents use downloaded relationship and gender IDs, are appended to
  the persisted offline enrolment, reject duplicate family MPIs, and are
  created in family → members → policies synchronization order.
- Existing HIV beneficiaries can be loaded by TARV/MPI, verified through the
  legacy HIV marker, edited for date of birth and gender, queued in SQLite, and
  synchronized through `updateInsuree` with MutationLog polling.

## In progress

### Production acceptance

- The policy GraphQL contracts and offline state transitions have automated
  contract/model/UI coverage. Acceptance against a client CSU backend and real
  master-data export remains required before production sign-off.
- Client deployment must provide `GLITCHTIP_DSN` and
  `CLAIMS_ARCHIVE_PASSWORD` through the protected build pipeline. Neither value
  is stored in source control.

## Existing application capabilities to preserve

- Secure login/session and optional biometric sign-in.
- Claim administrator setup and mapped claim catalogs.
- Claim entry, online FHIR submission, and SQLite offline claims.
- Insuree enquiry, family screens, policy renewal, feedback, indicators, and
  reports.

## Remaining acceptance and blocked work

- Validate the encrypted XML archive with a production web import after the
  client supplies deployment secrets and a test endpoint.
- Keep RFC-dependent transport, pregnancy-product routing, and temporary MPI
  linkage isolated until their backend contracts and business rules arrive.
