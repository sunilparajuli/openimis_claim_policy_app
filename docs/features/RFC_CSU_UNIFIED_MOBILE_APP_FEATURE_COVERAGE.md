# RFC: CSU Unified Mobile Application — Feature Coverage and Client Decisions

**RFC status:** Draft for client review

**Application:** Unified Claims, Policies CSU and Policies HIV mobile application

**Prepared:** 16 November 2026

**Specification reviewed:** `~/Downloads/features` (21 feature files, 344 scenarios)
**Primary mobile scope:** `mobile-app-new-version.feature` (35 scenarios)

## 1. Purpose

This document compares the requested CSU Cameroon mobile functionality with the current Flutter application. It identifies:

- functionality already covered;
- functionality that is partially covered;
- functionality that still needs development;
- behavior owned by the backend rather than the mobile application; and
- requirements that need a client or Product Owner decision before implementation.

The requested target is one unified Flutter application containing Claims, Policies CSU and Policies HIV. Combining the applications must not weaken the programme-specific business rules described below.

## 2. Requested client response

For every item marked **Decision required**, please provide one of the following responses:

- **Approved** — implement the behavior as proposed;
- **Change requested** — provide the corrected behavior;
- **Postpone** — exclude it from the first release; or
- **Out of scope** — do not implement it in the unified application.

Please also answer the API and business-rule questions in sections 7 and 8.

## 3. Executive summary

| Coverage | Count | Meaning |
|---|---:|---|
| Covered | 4 | The current Flutter code contains the required behavior. Production integration must still be validated. |
| Partially covered | 6 | A foundation exists, but part of the required workflow or validation is missing. |
| Not covered | 18 | Mobile implementation is required. |
| Backend responsibility | 3 | The requirement must be implemented or verified on the openIMIS backend. |
| Unclear, blocked or awaiting integration | 3 | A client decision, backend contract or production integration test is required. |
| Not applicable to Flutter | 1 | The original rule concerns the legacy web-based mobile application. Equivalent Flutter flows still require testing. |

The application currently provides a useful Claims foundation, including FHIR claim submission, offline storage, downloaded service/item prices, language handling and MPI normalization. It does not yet provide complete production CSU/HIV policy enrolment and synchronisation, Chèque Santé processing, programme-aware claims, selective claim upload, XML claim export, QR scanning or GlitchTip reporting.

## 4. Covered functionality

| ID | Feature | Current coverage | Acceptance/retest required |
|---|---|---|---|
| C-01 | Claims entered in the app synchronise | Claims can be submitted to the openIMIS FHIR R4 `Claim` endpoint. | Test against the client PostgreSQL environment with VIH and Chèque Santé claims. |
| C-02 | Health-facility service/item prices | The application downloads and displays prices from the selected HF price lists. | Confirm production values, including service `UVIH2` at HF `ES168`. |
| C-03 | Phone language | French phones use French; English phones use English; unsupported languages fall back to English. | Client validates translations and fallback behavior. |
| C-04 | MPI without spaces/invisible characters | MPI values are normalized in claim, enquiry, enrolment and renewal entry paths. | Retest typed and scanned values such as ` 120902348063480 `. |

### Client feedback for covered functionality

| ID | Client response | Comments |
|---|---|---|
| C-01 | ☐ Approved ☐ Change requested | |
| C-02 | ☐ Approved ☐ Change requested | |
| C-03 | ☐ Approved ☐ Change requested | |
| C-04 | ☐ Approved ☐ Change requested | |

## 5. Partially covered functionality

| ID | Feature | What exists | What remains |
|---|---|---|---|
| P-01 | Master-data download | ZIP/`MasterData.txt` download, parsing and local caching foundation exists. | Validate every required key against the production server and wire the data into all forms. |
| P-02 | Services belonging to the HF | HF price-list services are loaded. | Confirm and implement inclusion of services attached to no HF, plus programme filtering. |
| P-03 | Server-configured MPI and cheque lengths | `ModuleConfiguration` is read from master data. | Apply configured minimum/maximum values to forms and block invalid saves. |
| P-04 | Diagnosis and programme validation | Diagnoses can be selected locally. | Remove fallback diagnoses for production, add programme selection, and reject codes absent from master data with the required translated message. |
| P-05 | Generic server-error handling | Network and submission errors are caught. | Centralize the exact French/English generic message and distinguish business errors from server failures. |
| P-06 | Successful/failed upload reporting | Offline claims are synchronised one by one. | Current completion dialog ignores failed-count details. Show accurate success, partial-success and failure results. |

### Client feedback for partially covered functionality

| ID | Proposed completion accepted? | Comments/corrections |
|---|---|---|
| P-01 | ☐ Yes ☐ No ☐ Postpone | |
| P-02 | ☐ Yes ☐ No ☐ Postpone | |
| P-03 | ☐ Yes ☐ No ☐ Postpone | |
| P-04 | ☐ Yes ☐ No ☐ Postpone | |
| P-05 | ☐ Yes ☐ No ☐ Postpone | |
| P-06 | ☐ Yes ☐ No ☐ Postpone | |

## 6. Functionality not currently covered

### 6.1 Common application capabilities

| ID | Requested feature | Proposed implementation | Priority |
|---|---|---|---|
| N-01 | Hide the Settings menu | Remove user access to application Settings while retaining required internal/build configuration. | P0 |
| N-02 | Read every valid insuree QR code | Add a supported scanner and normalize the scanned MPI before enquiry or form use. | P1 |
| N-03 | Report errors to GlitchTip | Add error capture with environment and release tags for the unified application and its Claims/CSU/HIV modules. | P1 |
| N-04 | Temporary MPI linked to final MPI | Store and synchronise the temporary/final mapping and allow enquiry/search/sync with either value. | Blocked by backend contract |

### 6.2 Policies CSU and Policies HIV

| ID | Requested feature | Proposed implementation | Priority |
|---|---|---|---|
| N-05 | HIV enrolment creates only HIV insurees | Add a dedicated HIV/TARV enrolment mode and prevent CSU enrolment from incorrectly saving an HIV programme enrolment. | P0 |
| N-06 | Reject an all-numeric HIV MPI | Validate locally where possible and display the translated backend mutation error. | P0 |
| N-07 | Save changes to HIV patients | Persist and synchronise changed date of birth and gender, including conflict/error handling. | P0 |
| N-08 | Duplicate MPI used as family head | Check duplicates, show a clear re-entry message and prevent crashes. | P0 |
| N-09 | Product minimum/maximum age | Warn offline before save and retain backend validation as the authoritative check. Age limit `0` means no limit. | P0 |
| N-10 | Chèque Santé pregnancy week | Add a mandatory week selector from 1 to 42 and send the value as policy pregnancy age through GraphQL. | P0 |
| N-11 | Only a new cheque can be attached | Validate `New`, `Used` and unknown cheques and show the specified messages. Status matching remains case-sensitive. | P0 |

### 6.3 Claims

| ID | Requested feature | Proposed implementation | Priority |
|---|---|---|---|
| N-12 | Exactly one programme per claim | Add mandatory programme selection and store it in the offline and FHIR models. | P0 |
| N-13 | Filter services by programme and HF | Offer only services of the chosen programme that belong to the HF or have no HF. | P0, confirmation required |
| N-14 | Set claim source to `MOB` | Include the expected mobile source in the submission and verify it is stored by the backend. | P0 |
| N-15 | Correct duplicated-claim message | Map duplicate claim responses to a claim-creation message, never a policy-creation message. | P0 |
| N-16 | Select claims to upload | Add per-claim selection and a “select all” option; synchronise only the selected claims. | P0 |
| N-17 | Claim with unattributed cheque fails clearly | Capture the cheque number where required and display `Unknown cheque number` for an unattributed new cheque. | P1 |

### 6.4 Offline XML export

| ID | Requested feature | Proposed implementation | Priority |
|---|---|---|---|
| N-18 | Password-protected ZIP containing claim XML files | Generate one compatible XML file per claim and package the selected claims into a protected ZIP. | P1 |
| N-19 | Always use build-config password | Do not ask the user for an archive password; use only the CSU build-config password. | P1 |

### Client feedback for missing functionality

For each ID N-01 to N-19, please indicate: **Approved / Change requested / Postpone / Out of scope**.

| IDs | Client decision | Comments |
|---|---|---|
| N-01 to N-04 | | |
| N-05 to N-11 | | |
| N-12 to N-17 | | |
| N-18 to N-19 | | |

## 7. Backend-owned requirements and integration dependencies

These items cannot be completed or proven by Flutter code alone.

| ID | Requirement/dependency | Backend or client action required |
|---|---|---|
| B-01 | Master data served from cache | Verify the backend reads cached master-data objects instead of repeatedly querying PostgreSQL. |
| B-02 | Pregnancy age of a synced Chèque Santé claim | The backend computes claim pregnancy age. The app should not compute or submit it for a claim. |
| B-03 | XML-imported claims have source `XML` | Verify web import through `/api/tools/extracts/upload_claims` stores source `XML`. |
| B-04 | PostgreSQL claim compatibility | Provide a test environment and accounts for VIH and Chèque Santé end-to-end claim tests. |
| B-05 | Current user context | Confirm use of `/core/users/current_user` for officer, claim administrator, HF and module permissions. |
| B-06 | Policy GraphQL operations | Provide/confirm mutations, queries, payload examples and stable business-error codes for CSU and HIV enrolment/sync. |
| B-07 | FHIR programme and mobile-source fields | Confirm the production representation of `claim-program` and source `MOB`. |
| B-08 | XML archive contract | Provide representative accepted XML files, archive-password delivery mechanism and import test fixtures. |

## 8. Decisions and clarifications required

Implementation should not begin for the following items until the client confirms the rule.

### D-01 — Chèque Santé product by pregnancy age

Ticket `#37815` is open and the source specification says **TO CONFIRM**.

Please provide:

1. the pregnancy-week ranges;
2. the product offered for every range;
3. behavior when no product matches;
4. whether the rule applies offline before save, on the backend, or both; and
5. the effective date/version of the rule.

**Client response:**

______________________________________________________________________________

### D-02 — Dedicated transport tariff entry

Ticket `#35617` is open and only a preliminary model exists.

Please confirm:

1. required departure and arrival values;
2. season values and how the season is selected;
3. supported modes, currently described as motorbike and car;
4. tariff calculation ownership: app, backend or downloaded table;
5. offline behavior;
6. API/master-data fields; and
7. whether transport is separate from normal services in the submitted claim.

**Client response:**

______________________________________________________________________________

### D-03 — Programme-based service filtering

The source notes that programme filtering was originally specified for the web form only, while the consolidated mobile specification applies it to mobile.

**Proposed decision:** apply programme filtering in the unified mobile Claims form.

**Client response:** ☐ Approved ☐ Rejected ☐ Change requested

Comments: ____________________________________________________________________

### D-04 — Temporary MPI reconciliation

The requirement is postponed and no complete mobile/backend contract is available.

Please confirm:

1. which side creates the temporary MPI;
2. how the final MPI is received;
3. whether historical local claims/policies must be rewritten;
4. conflict behavior if either number already exists; and
5. the API used to create and retrieve the mapping.

**Client response:**

______________________________________________________________________________

### D-05 — Unified application access model

Please confirm how the single application decides which modules a user can access:

- server permissions/roles;
- assigned officer or claim administrator;
- health facility;
- downloaded programme configuration; or
- a combination of these.

The application should not infer authorization only from the programmes present in master data.

**Client response:**

______________________________________________________________________________

### D-06 — Legacy jQuery requirement

Flutter does not use jQuery or jQuery UI. We propose replacing this requirement with functional regression tests covering enrolment, policy attribution and synchronisation.

**Client response:** ☐ Approved ☐ Change requested

## 9. Proposed delivery slices

| Slice | Scope | Exit condition |
|---|---|---|
| 1 | Common user context, module access and production master data | Correct user/HF/programme context loads online and is safely retained offline. |
| 2 | Programme-aware Claims and accurate upload reporting | Claims contain programme and `MOB`, services are filtered correctly, and selected claims sync with accurate results. |
| 3 | CSU/HIV enrolment and policy synchronisation | Real enrolment/edit/renewal data persists and synchronises with all MPI and age rules. |
| 4 | Chèque Santé | Pregnancy week, cheque status and policy mutation work online/offline after D-01 approval. |
| 5 | XML export, QR and GlitchTip | Compatible protected archives, tested QR scanning and release-tagged monitoring are operational. |
| 6 | Transport | Implement only after D-02 and the backend contract are approved. |

## 10. Proposed acceptance approach

Each approved scenario should have:

1. a Flutter unit or widget test where practical;
2. an integration test against the supported openIMIS backend;
3. an offline test where the workflow is expected to work offline;
4. French and English message verification;
5. Android and iPhone Simulator validation; and
6. client acceptance using agreed test accounts and master data.

Performance testing should include a production-shaped data set containing approximately 30,000 combined medical services and items, because this volume was previously identified by the client. The test should measure download/parsing time, local storage, search/filter latency, form responsiveness and memory use on representative Android and iOS devices.

## 11. Sign-off

| Role | Name | Decision | Date | Comments |
|---|---|---|---|---|
| Client/Product Owner | | ☐ Approved ☐ Approved with changes ☐ Rejected | | |
| Backend representative | | ☐ APIs confirmed ☐ Changes required | | |
| Mobile representative | | ☐ Scope understood ☐ Questions remain | | |

Approval of this RFC confirms the feature scope and decisions, not the completion of implementation. Delivery acceptance will be recorded against the approved scenarios and test evidence.
