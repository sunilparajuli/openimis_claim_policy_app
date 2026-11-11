# Unclear or deferred CSU features

These requirements must not be guessed. Record the product-owner or backend
decision here before implementation.

## Product decisions required

- **Program filtering on mobile** (`#26990`, `#27063`, `#29303`): the
  consolidated mobile specification requires it, while its source comment says
  the original rule was written for the web form. Confirm the exact mobile
  behavior and data fields used to relate services/items to programs.
- **Chèque Santé product by pregnancy age** (`#37815`, open): obtain the RFC
  ranges and expected product codes.
- **Transport tariff entry** (`#35617`, open): confirm departure/arrival data,
  season values, transport modes, tariff lookup API, and offline behavior.
- **Temporary-to-final MPI linkage** (`#28689` and related, postponed): confirm
  identifier format, reconciliation API, conflict rules, and local references
  that must be rewritten.
- **Duplicate claim wording** (`#36144`, postponed): obtain the backend error
  code and approved French/English claim-specific text.

## External contracts required

- Obtain a real CSU `MasterData.txt` sample and document the record fields for
  every section. Current parsing deliberately retains unknown fields.
- Obtain the legacy Claims-app XML schema and at least one accepted archive.
- Obtain the build-config ZIP password delivery mechanism; never place the
  production password in source control.
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
