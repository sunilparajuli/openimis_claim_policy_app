# Unclear or deferred CSU features

These requirements must not be guessed. Record the product-owner or backend
decision here before implementation.

## Product decisions required

- **Chèque Santé product by pregnancy age** (`#37815`, open): obtain the RFC
  ranges and expected product codes.
- **Transport tariff entry** (`#35617`, open): confirm departure/arrival data,
  season values, transport modes, tariff lookup API, and offline behavior.
- **Temporary-to-final MPI linkage** (`#28689` and related, postponed): confirm
  identifier format, reconciliation API, conflict rules, and local references
  that must be rewritten.
- **Duplicate claim wording** (`#36144`, postponed): the app now always labels
  MutationLog failures as claim-creation errors and preserves backend detail.
  Obtain approved French/English wording only if the client wants text more
  specific than the backend response.

## External contracts required

- Obtain a real CSU `MasterData.txt` sample and document the record fields for
  every section. Current parsing deliberately retains unknown fields.
- Confirm the protected build pipeline values for `CLAIMS_ARCHIVE_PASSWORD`
  and `GLITCHTIP_DSN`; neither production secret is stored in source control.
- Run the implemented legacy-compatible AES/XML archive through the production
  web import as an acceptance test.
- Confirm how account rights distinguish Claims, Policies CSU, and Policies HIV
  inside one app.
- Confirm GlitchTip DSN provisioning, release names, environment names, and
  data-scrubbing requirements.

## Explicitly deferred statuses

- `@status-open` work is implemented only when explicitly requested.
- `@status-postponed` work remains planned but outside the current delivery.
- `@status-not-validated` behavior is retained and must receive acceptance
  coverage against the CSU backend.

The jQuery requirements describe the legacy policy applications and do not
apply to the native Flutter UI.
