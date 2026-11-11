# CSU unified app foundation

The CSU feature specifications live outside this repository in
`~/Downloads/features`. They describe one installable app that serves Claims,
Policies CSU, and Policies HIV workflows while relying on backend permissions
and downloaded master data to determine available operations.

## First implementation slice

The shared master-data foundation implements the documented download contract:

- `GET api/tools/extracts/download_master_data` using the logged-in HTTP client
- ZIP extraction of `MasterData.txt` and JSON parsing off the UI isolate
- Validation that all documented master-data sections are present
- Preservation of backend section values and unknown record fields
- Accessors for products, programs, cheques, and exposed frontend module settings
- Local caching of the original ZIP in application support storage for offline reload

Backend records are retained in their original JSON shape. The app should add
business-specific typed adapters only where a workflow needs them; it should not
require undocumented backend keys.

## Boundaries

Backend-only requirements, such as master-data database caching and PostgreSQL
implementation details, remain backend responsibilities. Mobile screens should
be driven by the `@mobile` scenarios in the consolidated specification. The
large web-only medical control and claims review workflows are not automatically
part of the mobile surface.

The current generic claim setup still uses its existing FHIR/GraphQL contract.
Migration to the CSU bundle should happen workflow by workflow so the current
generic app behavior remains available while CSU-specific integration is built.
