from pathlib import Path

from openpyxl import Workbook
from openpyxl.styles import Alignment, Border, Font, PatternFill, Side
from openpyxl.utils import get_column_letter


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "docs" / "features" / "CSU_Mobile_Feature_Gap_Matrix.xlsx"

FEATURES = [
    ("Shared", "Unified application shell", "Claims, Policies CSU and Policies HIV in one installation", "Partial", "Workspace and capability cards exist; Claims and CSU routes exist; HIV is informational only", "Complete dedicated workflow routing and authorization", "Capability/rights contract", "Clear next slice", "Local review"),
    ("Shared", "Authentication and session", "Case-insensitive openIMIS login and authenticated API access", "Available", "Secure login/session, token handling and optional biometric login", "Retest against CSU backend", "FHIR login/token API", "Retest", "Current Flutter app"),
    ("Shared", "Capability-based access", "Show Claims/CSU/HIV according to signed-in account rights", "Partial", "Capabilities can be derived from downloaded controls/programs", "Use authoritative per-user permissions", "User capability/permission mapping", "Contract needed", "Consolidated specification"),
    ("Shared", "Master-data ZIP download", "Download and parse MasterData.txt from authenticated endpoint", "Available", "ZIP download, required-section validation, isolate parsing and atomic cache", "Validate with real CSU archive", "GET /api/tools/extracts/download_master_data", "Retest", "Flutter CSU foundation"),
    ("Shared", "Offline master data", "Start offline from the last successful master-data bundle", "Available", "Cached ZIP reload and offline status are implemented", "Add schema/version migration strategy", "No new API", "Enhancement", "Flutter CSU foundation"),
    ("Shared", "Master-data status", "Show last sync and available products/programs/facilities", "Available", "Visible CSU workspace card with counts and retry", "Translate all new labels", "No new API", "Polish", "Current development slice"),
    ("Shared", "Phone language", "French -> French; English -> English; unsupported -> English", "Available", "Phone locale and runtime locale changes supported", "Acceptance test on Android and iOS", "No new API", "Retest", "#31838"),
    ("Shared", "MPI normalization", "Trim surrounding whitespace and invisible characters before sending", "Available", "Shared normalization used in principal entry paths", "Audit every scan/import path", "No new API", "Retest", "#38348"),
    ("Shared", "QR scanning", "Read every valid insuree QR code", "Partial", "Camera/QR infrastructure exists", "Validate all CSU QR formats and payload variants", "QR payload contract/sample set", "Contract needed", "#33467"),
    ("Shared", "Server-driven MPI/cheque lengths", "Use exposed frontend ModuleConfiguration values", "Partial", "Configuration is parsed but not connected to every form", "Apply 12/20/6 defaults and server values in Claims and Policies", "Configuration key names and sample values", "Clear next slice", "#36729 et al."),
    ("Shared", "Hide Settings", "No Settings drawer entry; archive password always build configured", "Missing", "Settings remains visible", "Hide prohibited settings and retain only permitted preferences elsewhere", "No new API", "Clear", "#36145 #36309"),
    ("Claims", "Claim entry and offline save", "Create claims offline with diagnoses, services and items", "Available", "Wizard, SQLite queue, totals and review exist", "Retest with CSU data", "Existing FHIR/GraphQL APIs", "Retest", "Current Flutter app"),
    ("Claims", "Facility price-list catalogue", "Offer HF services plus unassigned services using HF prices", "Partial", "Claim administrator and large demo catalog exist; Java reference proves price-list flow", "Connect cached/live CSU data and unassigned-service rule", "Service/item schema and HF association fields", "Clear next slice", "#28704 #29449 #34719"),
    ("Claims", "30,000 service/item performance", "Search and select smoothly with very large catalogues", "Partial", "30k services and 30k items can be mocked; UI uses searchable flows", "Benchmark startup, search, memory and persistence on Android/iOS", "Paginated catalogue or master-data sizing contract", "Clear next slice", "Performance request / Java OP-1199"),
    ("Claims", "Programme selection", "Every claim belongs to exactly one downloaded programme", "Missing", "No programme field in the Flutter claim model", "Add required programme selector and persistence", "Claim programme payload field/mapping", "Contract needed", "#26990 #27063"),
    ("Claims", "Programme-filtered services", "Offer services matching programme and HF/unassigned rules", "Missing", "No programme-to-service filtering", "Implement after programme/service schema confirmation", "Programme-to-service association fields", "Unclear", "#29303 TO CONFIRM"),
    ("Claims", "Diagnosis/program validation", "Block codes absent from local master data with code invalide", "Partial", "Diagnosis selection exists; strict CSU master-data validation not complete", "Validate diagnosis and programme at save time", "Diagnosis/program identifiers in master data", "Clear next slice", "#36775 #36978"),
    ("Claims", "Complex services/subitems", "Support Cameroon package services and component quantities/prices", "Partial", "Flutter catalog exists; Java Claims has proven OP-1199 implementation", "Port domain behavior and XML/FHIR mapping", "Complex service/subitem schema", "Clear after contract", "Java Claims 297b5a0"),
    ("Claims", "FHIR synchronization", "Synchronize mobile claims and record per-claim outcome", "Available", "FHIR submission and offline upload queue exist", "Align exact CSU payload and backend errors", "FHIR Claim contract", "Retest", "#27630 #35782 #35784"),
    ("Claims", "Source MOB", "Send and store source MOB for synchronized claims", "Unverified", "No verified explicit source mapping in current Flutter/Java review", "Add explicit supported payload field and integration test", "Backend-supported MOB source field/extension", "Contract needed", "#35077"),
    ("Claims", "Selectable claim upload", "Choose pending claims with Select all", "Missing", "Current queue upload does not implement required multi-selection", "Checkbox list, Select all/Clear all and selected-only upload", "No new API if claims upload individually", "Clear", "#37600 #34466 status-open"),
    ("Claims", "Duplicate claim message", "Show claim-creation message, never policy message", "Missing", "No dedicated duplicate error mapping", "Map stable backend duplicate code to localized claim message", "Stable duplicate-claim error code/shape", "Contract needed", "#36144 postponed"),
    ("Claims", "Successful upload reporting", "Never show server-error text after successful upload", "Partial", "Success/error state separation exists but needs end-to-end validation", "Separate upload success from refresh/follow-up failure", "Stable success response contract", "Clear", "#34599 status-open"),
    ("Claims", "XML archive export", "Password-protected ZIP; one compatible XML per claim", "Partial", "Offline infrastructure exists; exact legacy contract is not validated", "Implement/validate selected-claim export and accepted XML schema", "Accepted XML sample/schema", "Contract needed", "#36904"),
    ("Claims", "Build-only archive password", "Never accept a user-defined ZIP password", "Missing", "Settings behavior must be removed/locked", "Use flavor/build secret only", "Secure build-config secret delivery", "External dependency", "#34476 #34647 #34660"),
    ("Claims", "Chèque claim validation", "Unattributed cheque fails with Unknown cheque number", "Missing", "No claim cheque field/workflow", "Add cheque input only if required by backend claim contract", "Cheque field and validation error contract", "Contract needed", "#36111 not-validated"),
    ("Claims", "Pregnancy age on claim", "Backend computes it; app does not send it", "Compatible", "No mobile claim pregnancy computation is required", "Ensure payload omits pregnancy age", "Backend behavior confirmation", "Retest", "#36111 #36258"),
    ("Claims", "Dedicated transport tariff", "Departure/arrival/season/mode without full service list", "Missing", "No dedicated transport workflow", "Wait for confirmed data model and tariff API", "Transport tariff calculation contract/API", "Blocked by product decision", "#35617 status-open"),
    ("Policies CSU", "Family and beneficiary enrolment", "Create/edit families, heads and dependants offline", "Partial", "Forms and family screens exist", "Replace hard-coded lists; complete offline sync fidelity", "Family/insuree mutation contract", "Clear next slice", "Current Flutter + Java Policies"),
    ("Policies CSU", "Duplicate head MPI", "Validation message without crash", "Partial", "Basic validation exists", "Verify server duplicate response and offline duplicate check", "Stable duplicate-MPI error code", "Contract needed", "#34496 #34733"),
    ("Policies CSU", "Product age limits", "Apply minAge/maxAge, zero meaning unlimited", "Missing", "Master-data accessors exist but forms do not enforce rules", "Add offline warning and retain backend authority", "Existing product fields; sync error contract", "Clear", "#33444 et al."),
    ("Policies CSU", "Pregnancy week", "Mandatory week 1-42 for Chèque Santé policies", "Missing", "No Chèque Santé policy form", "Add conditional selector and offline persistence", "Policy pregnancyAge mutation field", "Contract needed", "#35088 #35207"),
    ("Policies CSU", "Cheque validation", "Only New cheque accepted; distinguish Used and unknown", "Missing", "Cheques parsed from master data but not connected", "Add entry, local state feedback and backend error mapping", "Cheque identifier/status fields and mutation contract", "Contract needed", "#27168 #35627 #28691"),
    ("Policies CSU", "Product by pregnancy age", "Offer Chèque Santé product according to pregnancy age", "Blocked", "Exact mapping is absent", "Obtain and approve RFC before implementation", "Pregnancy-age/product rule or decision API", "Product decision", "#37815 status-open"),
    ("Policies HIV", "Dedicated HIV enrolment", "Only HIV insurees; CSU app cannot create HIV programme policy", "Missing", "Capability card exists but no dedicated form", "Implement separate mode, validation and sync model", "HIV marker/type and programme mutation fields", "Contract needed", "#27282 #27337"),
    ("Policies HIV", "All-numeric MPI rejection", "Reject all-numeric HIV CHFID with translated backend message", "Missing", "General MPI normalization exists; HIV-specific rule absent", "Add offline validation and backend error mapping", "mutation.insuree.mpi_entirely_numeric_error", "Clear", "#38348"),
    ("Policies HIV", "Edit HIV DOB and gender", "Synchronize changed date of birth and gender", "Missing", "No dedicated HIV edit flow", "Implement and integration-test update mutation", "HIV insuree update mutation contract", "Contract needed", "#38086"),
    ("Policies", "Temporary MPI linking", "Temporary offline MPI resolves to final MPI everywhere", "Blocked", "No linking model or API contract", "Design only after backend model and resolution rules are supplied", "Create/link/query temporary MPI APIs", "Backend enhancement likely", "#28689 et al. postponed"),
    ("Policies", "Offline enrolment synchronization", "Upload family, insuree, policy and contribution changes", "Partial", "Screens and some repositories exist; complete CSU payload not verified", "Implement durable entity states and ordered retry", "Family/insuree/policy/contribution mutation contracts", "Clear after contract", "Java Policies reference"),
    ("Robustness", "Generic server message", "Localized generic message for backend server failures", "Partial", "Central network error handling exists", "Normalize all workflow-specific failure paths", "No new API", "Clear", "#34219"),
    ("Robustness", "GlitchTip releases", "Separate release tag per Claims, CSU and HIV workflow", "Partial", "Error infrastructure exists; workflow release strategy not confirmed", "Configure DSN, environment and release naming", "GlitchTip provisioning/configuration", "External dependency", "#34210 #34243"),
]

APIS = [
    ("Authentication", "FHIR login/token", "Available", "Used by the current application", "Confirm case-insensitive username behavior on CSU backend", "Backend/API"),
    ("Master data", "GET /api/tools/extracts/download_master_data", "Available", "Documented ZIP containing MasterData.txt", "Provide a production-like CSU sample and schema examples", "Backend/API"),
    ("Authorization", "Per-user Claims/CSU/HIV capabilities", "Contract needed", "No authoritative field mapping supplied", "Document permission codes/roles and response location", "Backend contract"),
    ("Claims", "FHIR Claim create", "Available", "Current app can submit claims", "Document programme and MOB-source representation plus duplicate error shape", "Backend contract"),
    ("Claims", "Claim programme field", "Contract needed", "Specification requires one programme per claim", "Define FHIR extension/field and accepted code values", "Backend contract"),
    ("Claims", "Programme-to-service association", "Contract needed", "Required for programme filtering", "Expose association in master data or a documented catalogue API", "Backend data contract"),
    ("Catalog", "HF/unassigned services and price lists", "Partially available", "Java app uses GraphQL price-list UUIDs; master-data fields need confirmation", "Document master-data record fields and pagination expectations", "Backend contract"),
    ("Catalog", "Complex service/subservice/subitem schema", "Contract needed", "Java OP-1199 is a reference but not the formal CSU contract", "Provide GraphQL/master-data schema and XML/FHIR mapping", "Backend contract"),
    ("Policies", "Create/update family and insuree", "Available but unverified", "Generic GraphQL mutations exist", "Provide CSU/HIV required fields and stable errors", "Backend/API"),
    ("Policies", "Create/update policy and contribution", "Available but unverified", "Generic mutations exist", "Confirm pregnancyAge, cheque and programme fields", "Backend/API"),
    ("HIV", "HIV type/marker/TARV enrolment fields", "Contract needed", "Not present in audited Java mobile payloads", "Document mutation inputs and programme enforcement", "Backend contract"),
    ("HIV", "All-numeric MPI error", "Specified", "Expected error key is documented", "Confirm transport/status code and translation variables", "Backend contract"),
    ("Cheque", "Cheque list/status in master data", "Specified but sample needed", "MasterData.txt includes cheques", "Provide exact identifier/status/beneficiary field names", "Backend data contract"),
    ("Cheque", "Policy cheque attachment", "Contract needed", "Required outcomes are specified, payload is not", "Document mutation field and Used/unknown error codes", "Backend contract"),
    ("Cheque", "Pregnancy age on policy", "Contract needed", "GraphQL synchronization is required", "Document input field, type and validation", "Backend contract"),
    ("Cheque", "Pregnancy-age product rule", "Product decision missing", "RFC mapping is explicitly TO CONFIRM", "Approve RFC or expose authoritative product eligibility API", "Product/backend decision"),
    ("MPI", "Temporary-to-final MPI link", "Backend enhancement likely", "No mobile/backend contract supplied", "Provide create-link mutation and resolution/search behavior", "Backend/API"),
    ("Transport", "Transport tariff calculation", "Backend enhancement likely", "Data model and computation are TO CONFIRM", "Define departure, arrival, season, mode and tariff response", "Backend/API"),
    ("XML", "Accepted Claims XML schema/sample", "External contract needed", "Archive format must not change", "Provide accepted fixture and import validation environment", "Integration contract"),
    ("Build", "Standard archive password delivery", "External contract needed", "Secret must not be stored in source or user settings", "Define CI/flavor secret injection", "DevOps"),
    ("Observability", "GlitchTip DSN/release/environment", "External configuration needed", "Behavior is specified but provisioning is not", "Supply DSNs and release naming convention", "DevOps"),
]

JAVA = [
    ("Claims develop", "Claim lifecycle, FHIR upload, per-claim status", "Port behavior, not UI/code", "Strong reference"),
    ("Claims 297b5a0", "Cameroon complex services, subservices/subitems, pagination", "Port domain rules after schema confirmation", "Directly relevant"),
    ("Claims develop", "HF price-list services/items and large catalogue persistence", "Use for 30k catalogue architecture", "Directly relevant"),
    ("Claims develop", "XML-per-claim protected ZIP export", "Retain format but remove mutable password", "Partial reference"),
    ("Claims develop", "Upload all pending claims", "Do not copy; add selection and Select all", "Conflicts with specification"),
    ("Claims develop", "Visible Settings and mutable archive password", "Do not copy", "Conflicts with specification"),
    ("Policies develop", "Family/insuree/policy/premium/renewal workflows", "Port behavior and sequencing", "Strong reference"),
    ("Policies Gambia/Niger", "Combined complete-enrolment synchronization", "Useful offline sync architecture", "Country rules must not be copied"),
    ("Policies feature-34418", "Signature capture", "Out of current CSU specification", "Do not prioritize"),
    ("Policies COM", "Polygamous/subfamily flows", "Country-specific and out of scope", "Do not port"),
    ("Both csu-to-merge PRs", "About-page version only", "No CSU functionality to port", "Misleading branch name"),
]


HEADER_FILL = PatternFill("solid", fgColor="2F5597")
HEADER_FONT = Font(color="FFFFFF", bold=True)
SECTION_FILL = PatternFill("solid", fgColor="D9EAF7")
THIN = Side(style="thin", color="D9E1F2")
STATUS_COLORS = {
    "Available": "C6E0B4",
    "Compatible": "C6E0B4",
    "Partial": "FFE699",
    "Unverified": "F4B183",
    "Missing": "F4CCCC",
    "Blocked": "D9D2E9",
    "Contract needed": "F4B183",
    "Backend enhancement likely": "D9D2E9",
    "External contract needed": "D9D2E9",
    "External configuration needed": "D9D2E9",
    "Product decision missing": "D9D2E9",
    "Specified": "C6E0B4",
    "Partially available": "FFE699",
    "Available but unverified": "FFE699",
}


def add_table(ws, headers, rows, widths, freeze="A2"):
    ws.append(headers)
    for cell in ws[1]:
        cell.fill = HEADER_FILL
        cell.font = HEADER_FONT
        cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
    for row in rows:
        ws.append(row)
    ws.freeze_panes = freeze
    ws.auto_filter.ref = ws.dimensions
    ws.row_dimensions[1].height = 34
    for row in ws.iter_rows(min_row=2):
        for cell in row:
            cell.alignment = Alignment(vertical="top", wrap_text=True)
            cell.border = Border(bottom=THIN)
    for index, width in enumerate(widths, 1):
        ws.column_dimensions[get_column_letter(index)].width = width
    ws.sheet_view.showGridLines = False


def color_status_column(ws, column):
    for cell in ws.iter_cols(min_col=column, max_col=column, min_row=2):
        for item in cell:
            color = STATUS_COLORS.get(str(item.value))
            if color:
                item.fill = PatternFill("solid", fgColor=color)
                item.font = Font(bold=True)


def build_workbook():
    wb = Workbook()
    summary = wb.active
    summary.title = "Executive Summary"
    summary.sheet_view.showGridLines = False
    summary["A1"] = "CSU Cameroon Unified Mobile App — Feature & API Gap Matrix"
    summary["A1"].font = Font(size=18, bold=True, color="FFFFFF")
    summary["A1"].fill = HEADER_FILL
    summary.merge_cells("A1:F1")
    summary["A2"] = "Prepared from the consolidated CSU specification, current Flutter codebase, and Java Claims/Policies branch audits."
    summary.merge_cells("A2:F2")
    summary["A3"] = "Generated: 2026-11-12"
    summary.merge_cells("A3:F3")

    counts = {}
    for row in FEATURES:
        counts[row[3]] = counts.get(row[3], 0) + 1
    summary.append([])
    summary.append(["Current Flutter status", "Count", "Meaning"])
    for cell in summary[5]:
        cell.fill = HEADER_FILL
        cell.font = HEADER_FONT
    meanings = {
        "Available": "Implemented; requires proportionate CSU acceptance testing",
        "Compatible": "Current behavior already matches the stated requirement",
        "Partial": "Foundation or generic flow exists; CSU completion remains",
        "Unverified": "Likely present but exact backend contract is not proven",
        "Missing": "Not implemented in the Flutter app",
        "Blocked": "Requires product decision or backend contract/enhancement",
    }
    for status in ("Available", "Compatible", "Partial", "Unverified", "Missing", "Blocked"):
        summary.append([status, counts.get(status, 0), meanings[status]])
    summary.append([])
    start = summary.max_row + 1
    summary.cell(start, 1, "Recommended delivery order")
    summary.cell(start, 1).fill = HEADER_FILL
    summary.cell(start, 1).font = HEADER_FONT
    summary.merge_cells(start_row=start, start_column=1, end_row=start, end_column=6)
    priorities = [
        "1. Connect master-data programmes, diagnoses, products, services and items to real forms.",
        "2. Add Claims programme selection, facility/programme filtering and 30k catalogue benchmarks.",
        "3. Add pending-claim multi-selection, Select all, selected-only upload and precise outcomes.",
        "4. Validate legacy XML export and enforce build-config-only archive password; hide Settings.",
        "5. Complete Policies CSU offline enrolment, age limits, pregnancy week and cheque handling.",
        "6. Build a distinct Policies HIV workflow after mutation fields and programme rules are confirmed.",
        "7. Keep pregnancy-product rules, transport tariffs and temporary MPI blocked until contracts are approved.",
    ]
    for value in priorities:
        summary.append([value])
        summary.merge_cells(start_row=summary.max_row, start_column=1, end_row=summary.max_row, end_column=6)
    for row in summary.iter_rows():
        for cell in row:
            cell.alignment = Alignment(vertical="top", wrap_text=True)
    for col, width in zip("ABCDEF", (30, 12, 42, 18, 18, 18)):
        summary.column_dimensions[col].width = width
    color_status_column(summary, 1)

    features = wb.create_sheet("Feature Matrix")
    add_table(
        features,
        ["Area", "Feature", "Required behavior", "Flutter status", "What we have", "What remains", "API / dependency", "Next decision", "Source"],
        FEATURES,
        (16, 29, 45, 16, 48, 46, 38, 22, 24),
    )
    color_status_column(features, 4)

    apis = wb.create_sheet("Missing & Unclear APIs")
    add_table(
        apis,
        ["Area", "API / contract", "Status", "Evidence", "Required action", "Owner type"],
        APIS,
        (16, 38, 25, 54, 55, 24),
    )
    color_status_column(apis, 3)

    java = wb.create_sheet("Java Reference")
    add_table(
        java,
        ["Repository / branch", "Functionality found", "Flutter use", "Assessment"],
        JAVA,
        (31, 58, 56, 28),
    )

    legend = wb.create_sheet("Legend & Sources")
    legend_rows = [
        ("Available", "Implemented in Flutter; acceptance testing may remain"),
        ("Compatible", "No new implementation required for this rule"),
        ("Partial", "Some foundation or generic behavior exists"),
        ("Unverified", "Implementation cannot be declared compliant without backend/integration evidence"),
        ("Missing", "Required feature is not implemented"),
        ("Blocked", "A decision, contract, sample, credential or backend enhancement is required"),
        ("Source", "Consolidated specification supplied in the project conversation"),
        ("Source", "docs/features/ADDED_FEATURES.md"),
        ("Source", "docs/features/UNDERSTOOD_FEATURES.md"),
        ("Source", "docs/features/UNCLEAR_FEATURES.md"),
        ("Source", "docs/features/JAVA_CLAIMS_BRANCH_AUDIT.md"),
        ("Source", "docs/features/JAVA_POLICIES_BRANCH_AUDIT.md"),
    ]
    add_table(legend, ["Term", "Definition / source"], legend_rows, (26, 100))
    color_status_column(legend, 1)

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    wb.save(OUTPUT)


if __name__ == "__main__":
    build_workbook()
    print(OUTPUT)
