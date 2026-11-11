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

## Existing application capabilities to preserve

- Secure login/session and optional biometric sign-in.
- Claim administrator setup and mapped claim catalogs.
- Claim entry, online FHIR submission, and SQLite offline claims.
- Insuree enquiry, family screens, policy renewal, feedback, indicators, and
  reports.

## Next clear implementation slice

- Connect CSU master-data synchronization to post-login startup.
- Derive Claims/CSU/HIV capabilities from the authenticated user and downloaded
  data.
- Replace hard-coded policy/enrolment lists with cached master-data sections.
