# openIMIS API inventory

All paths are relative to `API_BASE_URL`. Live mode sends them to the configured
openIMIS deployment. Demo mode handles supported contracts locally through
`OpenImisMockInterceptor`.

## REST and FHIR

| Method | Path | Purpose | Implementation |
| --- | --- | --- | --- |
| `POST` | `api/api_fhir_r4/login/` | Authenticate and return token/expiry | `OpenImisAuthRepository` |
| `GET` | `api/api_fhir_r4/Practitioner/` | Validate Claim Admin and facility | `ClaimSetupRepository` |
| `GET` | `api/api_fhir_r4/CodeSystem/diagnosis/` | Download diagnoses | `ClaimSetupRepository` |
| `POST` | `api/api_fhir_r4/Claim/` | Submit an FHIR claim | `ClaimRepository` |
| `POST` | `rest/api/policy/commissions` | Retrieve officer commissions | `ReportRepository` |

The commission API requires header `api-version: 3`. Its legacy request field
`insrance_product_code` is intentionally misspelled to match the server contract.

## GraphQL

GraphQL requests use `POST api/graphql` with a standard `{query, variables}`
body through `NativeGraphQLService`.

| Operation | Purpose | Implementation |
| --- | --- | --- |
| `ClaimMobileSetup` | Claim Admin facility, service price list, item price list | `ClaimSetupRepository` |
| `InsureeProfileQuery` | Insuree, policies, facility, and benefit balances | `InsureeRepository` |
| `GetSnapshotPolicies` | Policy counts at a selected date | `ReportRepository` |
| `GetCumulativePolicies` | New/renewed/suspended/expired counts over a period | `ReportRepository` |
| `RenewPolicyMutation` | Submit policy renewal | `PolicyRenewalPage` workflow |

## Authentication

`AuthInterceptor` attaches the stored bearer token. Authentication data is kept
in secure storage. `RetryInterceptor` retries transient connection and server
errors, but claim creation disables automatic retry to prevent duplicate writes.

## Adding an endpoint

1. Add the operation to a feature repository, not a widget.
2. Use `HttpService` for REST/FHIR or `NativeGraphQLService` for GraphQL.
3. Parse the response into typed domain models.
4. Add error and success tests.
5. If demo mode needs the operation, add a contract-compatible response to
   `OpenImisMockInterceptor` and test it separately.
6. Update this inventory.
