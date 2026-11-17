#!/usr/bin/env python3
"""Generate an auditable CSU feature inventory and Flutter coverage workbook."""

from __future__ import annotations

import re
from pathlib import Path

from openpyxl import Workbook
from openpyxl.styles import Alignment, Font, PatternFill
from openpyxl.utils import get_column_letter


ROOT = Path(__file__).resolve().parents[1]
FEATURE_DIR = Path.home() / "Downloads" / "features"
OUTPUT = ROOT / "docs" / "features" / "CSU_FULL_GHERKIN_COVERAGE.xlsx"


# Classification is deliberately about the current Flutter worktree. Backend-only
# requirements are retained as dependencies instead of being reported as missing UI.
COVERAGE = {
    "The master data download works on PostgreSQL": ("Partial", "Client implemented; backend verification required", "lib/feature/shared/repositories/csu_master_data_repository.dart"),
    "The app downloads only the services of its health facility": ("Partial", "HF price-list services load, but inclusion of services with no HF is not proven", "lib/feature/claims/repositories/claim_setup_repository.dart"),
    "The mobile service price is the HF price list price": ("Implemented", "Service and item price-list prices are parsed", "lib/feature/claims/repositories/claim_setup_repository.dart"),
    "Master data is served from the cache": ("Backend dependency", "Server-side cache behavior; no Flutter implementation", "Backend / core cache"),
    "Configurable MPI and cheque length in the Claims app": ("Partial", "ModuleConfiguration is downloaded, but limits are not applied to Claims inputs", "lib/feature/shared/models/csu_master_data.dart; lib/feature/claims/presentation/claim_wizard_page.dart"),
    "The Settings menu is hidden": ("Missing", "Settings is exposed from Home and Profile", "lib/feature/home/home_page.dart; lib/feature/home/profile_page.dart"),
    "The apps follow the phone language": ("Implemented", "French maps to French; all unsupported languages map to English", "lib/core/localization/locale_provider.dart"),
    "The app sends the MPI without spaces or invisible characters": ("Implemented", "MPI normalization is used in claims, enquiry, enrolment and renewal", "lib/core/utils/insuree_number.dart"),
    "All insuree QR codes are readable": ("Missing", "No QR/barcode scanner dependency or scanner flow", "pubspec.yaml"),
    "A temporary MPI number is linked to the final MPI number": ("Blocked / missing", "No mobile mapping workflow; backend contract is postponed", "Backend API and mobile data model required"),
    "The HIV app enrols only HIV insurees": ("Missing", "No dedicated HIV/TARV enrolment workflow", "lib/feature/policies"),
    "An all-numeric MPI is refused for an HIV patient": ("Missing", "No HIV-specific validation or translated backend mutation handling", "lib/feature/policies"),
    "Changes to an HIV patient are saved": ("Missing", "No persisted HIV edit/synchronisation workflow", "lib/feature/policies"),
    "A duplicate MPI as family head shows a message": ("Missing", "Current family enrolment is an in-memory prototype and does not check the backend", "lib/feature/policies/presentation/family_enrolment_page.dart"),
    "The product age limits are checked at synchronisation": ("Missing", "Products are downloaded but minAge/maxAge are not enforced in policy flows", "lib/feature/shared/models/csu_master_data.dart; lib/feature/policies"),
    "The pregnancy week dropdown": ("Missing", "No mandatory 1-42 pregnancy-age field or GraphQL mapping", "lib/feature/policies"),
    "Only a new cheque can be attached to a policy": ("Missing", "No cheque selection/status validation or policy sync", "lib/feature/policies"),
    "The Chèque Santé product offered depends on the pregnancy age": ("Unclear / blocked", "Open requirement explicitly marked TO CONFIRM; product-selection rule absent", "PO rule for #37815 and backend contract"),
    "Claims entered in the app synchronise": ("Implemented", "Claims submit to the openIMIS FHIR R4 Claim endpoint", "lib/feature/claims/repositories/claim_repository.dart"),
    "A claim belongs to exactly one programme": ("Missing", "Claim model/form has no programme and services are not filtered by programme", "lib/feature/claims/models/claim_submission_model.dart"),
    "Diagnosis and programme must exist in the master data": ("Partial", "Diagnosis is selected locally, but fallback data is hardcoded and programme is absent", "lib/feature/claims/repositories/claim_repository.dart"),
    "The backend computes the pregnancy age of a synced Chèque Santé claim": ("Backend dependency", "App currently does not send claim pregnancy age, as required", "Backend claim mutation"),
    "Syncing a claim with an unattributed cheque fails": ("Missing", "Claim workflow has no cheque number or cheque-specific error mapping", "lib/feature/claims"),
    "A synced claim has the source MOB": ("Missing", "FHIR Claim JSON does not send the MOB source", "lib/feature/claims/models/claim_submission_model.dart"),
    "Mobile claims sync after the PostgreSQL migration": ("Needs integration test", "FHIR submission exists; compatibility with the target backend is unverified", "lib/feature/claims/repositories/claim_repository.dart"),
    "A duplicated claim sync shows a claim message": ("Missing", "No duplicate-claim-specific response mapping", "lib/feature/claims/presentation/claim_wizard_page.dart"),
    "The user selects the claims to upload": ("Missing", "Offline sheet always syncs every pending claim and has no selection controls", "lib/feature/claims/presentation/offline_claims_sheet.dart"),
    "The exported archive is a password-protected ZIP of claim XML files": ("Missing", "No claim XML serializer/export workflow", "lib/feature/claims"),
    "The archive is never protected by a user-defined password": ("Missing", "Fixed-password archive export is absent", "assets/config; lib/feature/claims"),
    "A claim imported by XML has source XML": ("Backend dependency", "Web import behavior; Flutter must preserve archive contract", "POST /api/tools/extracts/upload_claims"),
    "The apps report errors to GlitchTip": ("Missing", "No Sentry/GlitchTip dependency or initialization", "pubspec.yaml; lib"),
    "Server errors show a generic message": ("Partial", "Errors are caught, but the required localized generic message is not centralized", "lib/feature/claims/presentation/claim_wizard_page.dart"),
    "A successful upload is not reported as a server error": ("Partial / defect", "Offline sync always displays a success dialog and omits failedCount", "lib/feature/claims/presentation/offline_claims_sheet.dart"),
    "Up-to-date web libraries in the Policies apps": ("Not applicable / retest", "Flutter does not use jQuery; equivalent enrolment and sync flows still need implementation tests", "pubspec.yaml; lib/feature/policies"),
    "Dedicated transport tariff entry": ("Unclear / blocked", "Open requirement is TO CONFIRM and no tariff API/data contract is defined", "PO/backend contract for #35617"),
}


def parse_files():
    rows = []
    scenario_re = re.compile(r"^\s*(Scenario(?: Outline)?):\s*(.+?)\s*$")
    rule_re = re.compile(r"^\s*Rule:\s*(.+?)\s*$")
    feature_re = re.compile(r"^\s*Feature:\s*(.+?)\s*$")
    for path in sorted(FEATURE_DIR.glob("*.feature")):
        feature = rule = ""
        tags = []
        lines = path.read_text(encoding="utf-8").splitlines()
        for number, line in enumerate(lines, 1):
            match = feature_re.match(line)
            if match:
                feature = match.group(1)
            match = rule_re.match(line)
            if match:
                rule = match.group(1)
            stripped = line.strip()
            if stripped.startswith("@"):
                tags = stripped.split()
                continue
            match = scenario_re.match(line)
            if not match:
                continue
            tag_text = " ".join(tags)
            if "@mobile" in tags:
                scope = "Mobile"
            elif "@backend" in tags:
                scope = "Backend/reference"
            elif "@frontend" in tags:
                scope = "Web frontend/reference"
            elif "@interop" in tags:
                scope = "Interoperability/reference"
            else:
                scope = "General/reference"
            status = next((tag.removeprefix("@status-") for tag in tags if tag.startswith("@status-")), "delivered/untagged")
            rows.append([path.name, number, feature, rule, match.group(1), match.group(2), tag_text, status, scope])
            tags = []
    return rows


def style_sheet(ws, widths):
    fill = PatternFill("solid", fgColor="51367A")
    for cell in ws[1]:
        cell.fill = fill
        cell.font = Font(color="FFFFFF", bold=True)
        cell.alignment = Alignment(vertical="top", wrap_text=True)
    ws.freeze_panes = "A2"
    ws.auto_filter.ref = ws.dimensions
    for index, width in enumerate(widths, 1):
        ws.column_dimensions[get_column_letter(index)].width = width
    for row in ws.iter_rows(min_row=2):
        for cell in row:
            cell.alignment = Alignment(vertical="top", wrap_text=True)


def main():
    if not FEATURE_DIR.is_dir():
        raise SystemExit(f"Feature directory not found: {FEATURE_DIR}")
    inventory = parse_files()
    canonical = [row for row in inventory if row[0] == "mobile-app-new-version.feature"]
    wb = Workbook()
    ws = wb.active
    ws.title = "Mobile Coverage"
    ws.append(["#", "Scenario", "Spec status", "Flutter coverage", "Finding", "Evidence / dependency", "Tags"])
    for index, row in enumerate(canonical, 1):
        title, tags, spec_status = row[5], row[6], row[7]
        coverage, finding, evidence = COVERAGE.get(title, ("Not assessed", "", ""))
        ws.append([index, title, spec_status, coverage, finding, evidence, tags])
    style_sheet(ws, [6, 48, 18, 22, 62, 58, 45])

    ws = wb.create_sheet("All 344 Scenarios")
    ws.append(["File", "Line", "Feature", "Rule", "Kind", "Scenario", "Tags", "Spec status", "Scope"])
    for row in inventory:
        ws.append(row)
    style_sheet(ws, [30, 8, 48, 42, 18, 62, 52, 18, 24])

    ws = wb.create_sheet("Build Backlog")
    ws.append(["Priority", "Work package", "Included canonical scenarios", "Main dependency"])
    backlog = [
        ("P0", "Real CSU/HIV policy persistence and synchronisation", "HIV-only enrolment; HIV validation/edit; duplicate head MPI; product age limits", "Policy GraphQL schema, authentication and backend error contract"),
        ("P0", "Programme-aware claim entry", "Exactly one programme; master-data validation; HF/unassigned/program service filtering; MOB source", "FHIR claim-program extension and production master data"),
        ("P0", "Selective and truthful claim upload", "Select claims + select all; duplicate message; no false server error", "Stable per-claim backend response/error codes"),
        ("P1", "Chèque Santé policy and claim support", "Pregnancy week; cheque status; unattributed cheque", "GraphQL fields/status contract; #37815 remains unclear"),
        ("P1", "Offline XML archive export", "Password ZIP; fixed build password; compatible claim XML", "Canonical XML schema and standard archive password delivery"),
        ("P1", "Configuration, navigation and observability", "Apply MPI/cheque limits; hide Settings; GlitchTip; generic errors", "Exposed ModuleConfiguration keys and GlitchTip DSN/releases"),
        ("P2", "QR scanning and temporary MPI", "Read all valid QR codes; temporary/final MPI mapping", "QR examples; postponed backend mapping API"),
        ("Blocked", "Pregnancy-based product and transport tariff", "Product by pregnancy age; dedicated transport", "PO confirmation and backend API/data contracts"),
    ]
    for item in backlog:
        ws.append(item)
    style_sheet(ws, [12, 42, 75, 65])

    ws = wb.create_sheet("API Gaps")
    ws.append(["Area", "Known contract", "Missing / must confirm"])
    api_rows = [
        ("Master data", "GET /api/tools/extracts/download_master_data", "Cache is backend-only; confirm authenticated ZIP behavior on target PostgreSQL server"),
        ("User context", "GET /core/users/current_user in source specs", "Flutter does not use it to derive claim_admin/officer/capabilities"),
        ("Claims", "FHIR R4 Claim; claim-program extension appears in fhir-interop.feature", "Confirm MOB source representation, duplicate error code, and programme/service validation"),
        ("Policy enrolment", "Specification says GraphQL, including policy pregnancy age", "Concrete mutations, offline sync payload, conflict/error mapping, HIV marker/TARV fields"),
        ("Cheques", "Master data includes cheques; backend statuses New/Used", "Policy attachment mutation and attributable-cheque validation response contract"),
        ("Temporary MPI", "Behavior specified but postponed", "Create/link/resolve API and offline reconciliation model"),
        ("XML export", "Web import POST /api/tools/extracts/upload_claims", "No upload API needed in app, but exact XML fixture/schema and archive password are required"),
        ("Transport", "No settled contract", "Tariff endpoint/data for departure, arrival, season and mode"),
        ("Observability", "GlitchTip with release tag per app", "DSN, environment, unified-app release naming and privacy rules"),
    ]
    for item in api_rows:
        ws.append(item)
    style_sheet(ws, [24, 65, 78])

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    wb.save(OUTPUT)
    print(f"Wrote {OUTPUT}")
    print(f"Inventory scenarios: {len(inventory)}; canonical mobile scenarios: {len(canonical)}")


if __name__ == "__main__":
    main()
