#!/usr/bin/env python3
"""Create a single-sheet client-facing CSU mobile feature status workbook."""

from pathlib import Path

from openpyxl import Workbook, load_workbook
from openpyxl.styles import Alignment, Border, Font, Side
from openpyxl.utils import get_column_letter


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "docs" / "features" / "CSU_Mobile_Features_Client_Status.xlsx"

DONE = [
    ("D-01", "Claim submission", "Done", "Claims can be submitted to the openIMIS FHIR R4 Claim endpoint."),
    ("D-02", "Offline claim storage", "Done", "Claims can be saved locally and uploaded later."),
    ("D-03", "HF service and item prices", "Done", "Service/item prices are read from the selected health-facility price lists."),
    ("D-04", "Phone language", "Done", "French uses French; English uses English; unsupported languages fall back to English."),
    ("D-05", "MPI cleanup", "Done", "Spaces and invisible characters are removed before MPI use/submission."),
    ("D-06", "Master-data download foundation", "Done", "Master-data ZIP download, parsing and local caching are implemented."),
    ("D-07", "Hide Settings", "Done", "Settings access is hidden from Home, the navigation drawer and Profile as required."),
    ("D-08", "Selective claim upload", "Done", "Users can select individual pending claims or use Select all, and only selected claims are uploaded."),
    ("D-09", "Accurate upload results", "Done", "The result distinguishes complete success from partial failure and reports uploaded/failed counts."),
    ("D-10", "Programme-aware claims", "Done", "A claim requires exactly one downloaded programme; it is persisted offline and submitted through the CSU GraphQL program field."),
    ("D-11", "Mobile claim source", "Done", "CSU GraphQL claim submission sends source MOB and leaves CCS pregnancy-age calculation to the backend."),
    ("D-12", "Programme/HF service filtering", "Done", "The catalogue uses the CSU backend HF-or-unassigned filter, filters by programme in the form, and preserves the HF price-list price when records overlap."),
    ("D-13", "Configured MPI and cheque lengths", "Done", "Claims and policy enrolment read the exposed fe-insuree/fe-policy ModuleConfiguration JSON, apply the documented defaults, and block invalid saves."),
    ("D-14", "Product age limits", "Done", "Policy enrolment applies downloaded minAge/maxAge rules before offline save and caps expiry at the limiting birthday; zero means unlimited."),
    ("D-15", "Chèque Santé pregnancy week", "Done", "The CSU policy form requires pregnancy week 1-42 and the GraphQL policy mutation sends pregnancyAge."),
    ("D-16", "Generic server-error messages", "Done", "HTTP 5xx responses use the required generic translated action message while business/client errors preserve their specific message."),
]


TODO = [
    ("T-01", "Complete production master-data integration", "Wire downloaded programmes, products, cheques, configuration and other master data into every form.", "P0"),
    ("T-02", "User role and module access", "Use server user context to show Claims, Policies CSU and Policies HIV only to authorized users.", "P0"),
    ("T-05", "Production CSU policy enrolment and sync", "Replace prototype/in-memory flows with persisted offline data and backend synchronisation.", "P0"),
    ("T-06", "Production HIV enrolment and sync", "Add TARV/HIV rules, numeric-MPI rejection and patient editing/synchronisation.", "P0"),
    ("T-07", "Duplicate family-head MPI", "Check duplicates and show a clear validation message without crashing.", "P0"),
    ("T-11", "Master-data code validation", "Reject diagnosis/programme codes not present locally; remove production fallback diagnoses.", "P0"),
    ("T-15", "Duplicate claim message", "Show a claim-creation message instead of a policy-creation message.", "P0"),
    ("T-17", "Cheque validation", "Handle New, Used, unknown and unattributed cheques with the required messages.", "P1"),
    ("T-18", "QR scanning", "Add and test scanning for every valid insuree QR format.", "P1"),
    ("T-19", "Claim XML archive export", "Export compatible claim XML files in a password-protected ZIP using only the build password.", "P1"),
    ("T-20", "GlitchTip error reporting", "Send errors with environment and release tags for the unified app/modules.", "P1"),
    ("T-22", "Temporary/final MPI mapping", "Support enquiry, search and synchronisation with either MPI.", "Blocked"),
    ("T-23", "Pregnancy-based product selection", "Offer the correct Chèque Santé product for the pregnancy age.", "Blocked"),
    ("T-24", "Dedicated transport entry", "Capture departure, arrival, season and mode and calculate the transport tariff.", "Blocked"),
    ("T-25", "30,000 service/item performance", "Test download, storage, filtering, search, UI latency and memory on Android and iOS.", "P1"),
]


CLIENT = [
    ("C-01", "Confirm unified-app access rules", "How are Claims, CSU and HIV modules authorized: roles, officer/claim-admin assignment, HF, programmes, or a combination?", "Required before T-02"),
    ("C-02", "Provide test environment and accounts", "Backend URL plus Claims, CSU and HIV accounts/HFs with representative permissions and data.", "Required for integration testing"),
    ("C-03", "Confirm policy GraphQL API", "Provide queries/mutations, example payloads and stable error codes for CSU/HIV enrolment, edit, renewal and sync.", "Required before T-05/T-06"),
    ("C-04", "Confirm FHIR claim fields", "Confirm production claim-program representation and how source MOB must be sent.", "Required before T-09/T-12"),
    ("C-05", "Confirm programme service filtering", "Confirm that the web programme-filter rule must also apply to mobile.", "Decision required"),
    ("C-06", "Define pregnancy-based product rule", "Provide pregnancy-week ranges and the Chèque Santé product for each range (#37815).", "Requirement currently unclear"),
    ("C-07", "Provide cheque API examples", "Confirm cheque attachment/status fields and responses for New, Used, unknown and unattributed cheques.", "Required before T-16/T-17"),
    ("C-08", "Define temporary MPI API", "Explain creation, final-number receipt, conflict handling, history updates and mapping API.", "Requirement postponed/blocked"),
    ("C-09", "Provide XML archive contract", "Provide accepted claim XML examples, ZIP fixture and secure delivery of the standard build password.", "Required before T-19"),
    ("C-10", "Provide GlitchTip configuration", "Provide DSN, environments, release naming and privacy/data rules.", "Required before T-20"),
    ("C-11", "Define transport tariff", "Confirm locations, seasons, modes, tariff ownership, offline behavior and API/master-data fields (#35617).", "Requirement currently unclear"),
    ("C-12", "Provide QR samples", "Provide examples of every valid insuree QR format and expected parsed MPI.", "Required before T-18 validation"),
    ("C-13", "Provide 30,000-item test data", "Provide production-shaped service/item data and target device/performance acceptance thresholds.", "Required for T-25"),
    ("C-14", "Approve priorities and scope", "Mark each requested item Approved, Postponed or Out of Scope for the first unified-app release.", "Client decision"),
]

EXTRA_FEATURES = [
    ("Secure login and saved session", "Existing extra feature", "Implemented", "Production authentication URL, roles and session-expiry policy."),
    ("Optional biometric sign-in", "Existing extra feature", "Implemented", "Client approval that biometric login is allowed by the security policy."),
    ("Claims listing and status tabs", "Existing extra feature", "Prototype", "Confirm whether the list must use FHIR/API data and which statuses/actions are required."),
    ("Insuree enquiry", "Existing extra feature", "Implemented foundation", "Production endpoint, permission and response/error examples."),
    ("Policy renewal", "Existing extra feature", "Prototype", "Renewal GraphQL/API contract and business rules."),
    ("Beneficiary feedback/audit survey", "Existing extra feature", "Prototype", "Confirm scope, questions, storage API and whether it belongs in the unified release."),
    ("Indicators dashboard", "Existing extra feature", "Prototype", "Confirm KPI definitions, report endpoints, filters and permissions."),
    ("Reports and commission view", "Existing extra feature", "Prototype", "Confirm required reports, source APIs and access rights."),
    ("About and support screens", "Existing extra feature", "Implemented", "Client support contact details and approved application/legal text."),
]

NON_FUNCTIONAL = [
    ("30,000 service/item performance", "Needs validation", "Production-shaped data, target devices and accepted timing/memory thresholds."),
    ("Offline-first reliability", "Needs development/testing", "Maximum offline period, conflict rules, retry policy and data-retention requirements."),
    ("Android and iOS support", "Needs validation", "Minimum Android/iOS versions and supported device list."),
    ("Security and privacy", "Needs confirmation", "Security policy, encryption expectations, PII logging restrictions and retention rules."),
    ("Accessibility", "Needs validation", "Required accessibility standard and supported text scaling/screen-reader expectations."),
    ("French and English localization", "Implemented foundation", "Approved translations and terminology glossary."),
    ("Automated and integration testing", "Needs development", "Stable test backend, test accounts and test-data reset process."),
    ("Release monitoring", "Needs development", "GlitchTip DSN, environments, release naming and incident ownership."),
]

TODO_CLIENT_REQUIREMENTS = {
    "Complete production master-data integration": "Production master-data ZIP and authenticated test endpoint.",
    "User role and module access": "Authoritative access-rule decision and current-user API examples.",
    "Hide Settings": "None; the specification is clear.",
    "Configured MPI and cheque lengths": "Production ModuleConfiguration key names and sample values.",
    "Production CSU policy enrolment and sync": "Production account/data for integration testing and confirmation that the mngoe CSU mutation contract is deployed.",
    "Production HIV enrolment and sync": "Production account/data plus confirmation of the legacy HIV marker and translated error catalog.",
    "Duplicate family-head MPI": "Duplicate-check API/response and expected offline behavior.",
    "Product age limits": "Production product examples and authoritative age calculation/time-zone rule.",
    "Programme-aware claims": "Confirm FHIR claim-program representation.",
    "Programme/HF service filtering": "Confirm this web rule applies to mobile and provide representative data.",
    "Master-data code validation": "Production diagnosis/programme master-data examples and error translations.",
    "Mobile claim source": "Confirm how source MOB is represented in production FHIR/API.",
    "Selective claim upload": "None; selection behavior is clear.",
    "Accurate upload results": "Stable backend success/business/server error responses.",
    "Duplicate claim message": "Duplicate error code and approved translated message.",
    "Chèque Santé pregnancy week": "Production confirmation that the mngoe pregnancyAge policy field is deployed.",
    "Cheque validation": "Cheque fields, status values and response examples.",
    "QR scanning": "Samples of every valid QR format.",
    "Claim XML archive export": "Accepted XML/ZIP fixtures and secure build-password delivery.",
    "GlitchTip error reporting": "DSN, environments, release naming and privacy rules.",
    "Generic server-error messages": "Approved English translation and business-error catalog.",
    "Temporary/final MPI mapping": "Mapping API and reconciliation/conflict rules.",
    "Pregnancy-based product selection": "Approved week-to-product rule for #37815.",
    "Dedicated transport entry": "Approved tariff rules, fields, master data and API for #35617.",
    "30,000 service/item performance": "Production-shaped dataset, devices and acceptance thresholds.",
}


def format_sheet(ws, widths):
    thin = Side(style="thin", color="B7B7B7")
    border = Border(left=thin, right=thin, top=thin, bottom=thin)
    ws.freeze_panes = "A2"
    ws.auto_filter.ref = ws.dimensions
    ws.sheet_view.showGridLines = False
    for cell in ws[1]:
        cell.font = Font(bold=True)
        cell.alignment = Alignment(vertical="center", wrap_text=True)
        cell.border = border
    ws.row_dimensions[1].height = 28
    for index, width in enumerate(widths, 1):
        ws.column_dimensions[get_column_letter(index)].width = width
    for row_number, row in enumerate(ws.iter_rows(min_row=2), 2):
        for cell in row:
            cell.alignment = Alignment(vertical="top", wrap_text=True)
            cell.border = border
        ws.row_dimensions[row_number].height = 45


def create_workbook():
    workbook = Workbook()
    sheet = workbook.active
    sheet.title = "All Features"
    sheet.append([
        "Feature",
        "Category",
        "Status",
        "Description",
        "Can develop now?",
        "Technical requirement from client",
    ])

    for _identifier, feature, _status, detail in DONE:
        sheet.append([
            feature,
            "Specified feature",
            "Done",
            detail,
            "Already implemented",
            "Production access and acceptance-test data for validation.",
        ])

    for _identifier, feature, work, priority in TODO:
        status = "Required from client" if priority == "Blocked" else "Needs development"
        description = work
        if priority == "Blocked":
            description = f"Client confirmation/API definition required. {work}"
        else:
            description = f"{work} Priority: {priority}."
        can_develop = "No — blocked by client/API decision" if priority == "Blocked" else "Yes"
        sheet.append([
            feature,
            "Non-functional requirement" if feature == "30,000 service/item performance" else "Specified feature",
            status,
            description,
            can_develop,
            TODO_CLIENT_REQUIREMENTS.get(feature, "Production API and acceptance examples."),
        ])

    for _identifier, request, detail, reason in CLIENT:
        sheet.append([
            request,
            "Client dependency",
            "Required from client",
            f"{detail} {reason}.",
            "No — client input required",
            detail,
        ])

    for feature, category, status, requirement in EXTRA_FEATURES:
        sheet.append([
            feature,
            category,
            status,
            "Present in the current Flutter application but not explicitly required by the consolidated mobile specification.",
            "Yes — after client confirms release scope" if status == "Prototype" else "Already implemented / validate",
            requirement,
        ])

    for feature, status, requirement in NON_FUNCTIONAL:
        sheet.append([
            feature,
            "Non-functional requirement",
            status,
            "Cross-cutting quality, platform or delivery requirement.",
            "Yes" if "confirmation" not in status.lower() else "Partially — confirmation required",
            requirement,
        ])

    format_sheet(sheet, [44, 28, 25, 72, 30, 80])

    workbook.properties.title = "CSU Mobile Features — Client Status"
    workbook.properties.subject = "What is done, what needs development, and what is required from the client"
    workbook.properties.creator = "CSU Mobile Development Team"
    workbook.save(OUTPUT)

    # Re-open to ensure the produced Office document is valid.
    check = load_workbook(OUTPUT, read_only=True)
    assert check.sheetnames == ["All Features"]
    assert check["All Features"].max_row - 1 == len(DONE) + len(TODO) + len(CLIENT) + len(EXTRA_FEATURES) + len(NON_FUNCTIONAL)
    check.close()
    print(f"Wrote {OUTPUT}")


if __name__ == "__main__":
    create_workbook()
