# Feature reference

## Authentication

Login uses the configured openIMIS FHIR login endpoint. Tokens and expiry are
stored with `SecureStorageService`. After the first password login, a user can
enable biometric sign-in if the device supports it. Biometrics can be disabled
from Settings and never replace server-side authentication.

## Claim Administrator setup

Claims features require a valid Claim Admin code. Setup validates the
Practitioner, resolves the health facility, and downloads diagnoses plus mapped
service/item price lists. The selected code is retained securely until cleared
from Settings.

## Claims

- create and review a claim
- select diagnoses through autocomplete
- select mapped services and items through autocomplete
- calculate responsive subtotals and total claim value
- submit an FHIR claim online
- save and upload claims through the offline queue
- browse accepted, rejected, and pending claim views
- inspect facility service/item mappings

Claim labels follow the Java Claims app terminology. Offline tables and status
semantics are documented in the root README.

## Insuree enquiry

Searches by Insurance No and retrieves the insuree, facility, policy status,
expiry, ceilings, deductibles, and remaining benefits. A claim can be started
from the selected insuree.

## Policies

- family and dependent enrolment
- policy renewal
- feedback survey
- snapshot and cumulative indicators
- reports and enrolment officer commissions

Policy operations use GraphQL where supported and the legacy commission REST
contract where required by the server.

## Settings

- language
- display currency
- biometric authentication
- camera, photo, and location permissions
- clear stored Claim Admin context
- logout and secure session cleanup
- legal, privacy, and about pages

## Shared platform behavior

- development and production flavors
- explicit live/demo data modes
- English and French localization
- centralized Material theme and fonts
- typed Riverpod dependency injection
- Dio authentication, retry, error, and logging interceptors
- reusable forms, buttons, sheets, status, feedback, and summary components

For implementation rules, setup, and extension examples, see the repository
[README](../../README.md).
