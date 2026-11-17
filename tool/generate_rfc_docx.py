#!/usr/bin/env python3
"""Render the client-facing CSU feature RFC Markdown as a Word document."""

from __future__ import annotations

import re
from pathlib import Path

from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.table import WD_CELL_VERTICAL_ALIGNMENT, WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs" / "features" / "RFC_CSU_UNIFIED_MOBILE_APP_FEATURE_COVERAGE.md"
OUTPUT = ROOT / "docs" / "features" / "RFC_CSU_UNIFIED_MOBILE_APP_FEATURE_COVERAGE.docx"
PURPLE = "51367A"
LIGHT_PURPLE = "EDE7F4"
LIGHT_GREY = "F2F2F2"


def set_cell_shading(cell, color: str) -> None:
    properties = cell._tc.get_or_add_tcPr()
    shading = properties.find(qn("w:shd"))
    if shading is None:
        shading = OxmlElement("w:shd")
        properties.append(shading)
    shading.set(qn("w:fill"), color)


def set_cell_margins(cell, value: int = 90) -> None:
    properties = cell._tc.get_or_add_tcPr()
    margins = properties.first_child_found_in("w:tcMar")
    if margins is None:
        margins = OxmlElement("w:tcMar")
        properties.append(margins)
    for side in ("top", "start", "bottom", "end"):
        element = margins.find(qn(f"w:{side}"))
        if element is None:
            element = OxmlElement(f"w:{side}")
            margins.append(element)
        element.set(qn("w:w"), str(value))
        element.set(qn("w:type"), "dxa")


def add_inline(paragraph, text: str, *, color: str | None = None) -> None:
    parts = re.split(r"(\*\*.*?\*\*|`.*?`)", text)
    for part in parts:
        if not part:
            continue
        run = paragraph.add_run(part.strip("*") if part.startswith("**") else part.strip("`") if part.startswith("`") else part)
        run.bold = part.startswith("**")
        if part.startswith("`"):
            run.font.name = "Courier New"
            run.font.size = Pt(9)
        if color:
            run.font.color.rgb = RGBColor.from_string(color)


def parse_table(lines: list[str], start: int):
    rows = []
    index = start
    while index < len(lines) and lines[index].strip().startswith("|"):
        cells = [cell.strip() for cell in lines[index].strip().strip("|").split("|")]
        rows.append(cells)
        index += 1
    if len(rows) > 1 and all(re.fullmatch(r":?-{3,}:?", cell.replace(" ", "")) for cell in rows[1]):
        rows.pop(1)
    return rows, index


def configure_document(document: Document) -> None:
    section = document.sections[0]
    section.top_margin = Inches(0.65)
    section.bottom_margin = Inches(0.65)
    section.left_margin = Inches(0.7)
    section.right_margin = Inches(0.7)

    normal = document.styles["Normal"]
    normal.font.name = "Aptos"
    normal.font.size = Pt(10)
    normal.paragraph_format.space_after = Pt(5)

    for level, size in ((1, 17), (2, 14), (3, 12)):
        style = document.styles[f"Heading {level}"]
        style.font.name = "Aptos Display"
        style.font.size = Pt(size)
        style.font.bold = True
        style.font.color.rgb = RGBColor.from_string(PURPLE)
        style.paragraph_format.space_before = Pt(10)
        style.paragraph_format.space_after = Pt(5)


def add_header_footer(document: Document) -> None:
    section = document.sections[0]
    header = section.header.paragraphs[0]
    header.text = "CSU Unified Mobile Application — Draft RFC for Client Review"
    header.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    for run in header.runs:
        run.font.size = Pt(8)
        run.font.color.rgb = RGBColor(110, 110, 110)

    footer = section.footer.paragraphs[0]
    footer.alignment = WD_ALIGN_PARAGRAPH.CENTER
    footer.add_run("Confidential — Client review copy  |  Page ")
    field = OxmlElement("w:fldSimple")
    field.set(qn("w:instr"), "PAGE")
    footer._p.append(field)
    for run in footer.runs:
        run.font.size = Pt(8)
        run.font.color.rgb = RGBColor(110, 110, 110)


def render() -> None:
    lines = SOURCE.read_text(encoding="utf-8").splitlines()
    document = Document()
    configure_document(document)
    add_header_footer(document)

    index = 0
    title_written = False
    while index < len(lines):
        line = lines[index].rstrip()
        stripped = line.strip()
        if not stripped:
            index += 1
            continue
        if stripped.startswith("|"):
            rows, index = parse_table(lines, index)
            table = document.add_table(rows=len(rows), cols=max(len(row) for row in rows))
            table.alignment = WD_TABLE_ALIGNMENT.CENTER
            table.style = "Table Grid"
            table.autofit = True
            for row_number, values in enumerate(rows):
                for column, value in enumerate(values):
                    cell = table.cell(row_number, column)
                    cell.text = ""
                    cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
                    set_cell_margins(cell)
                    paragraph = cell.paragraphs[0]
                    add_inline(paragraph, value)
                    for run in paragraph.runs:
                        run.font.size = Pt(8.5)
                    if row_number == 0:
                        set_cell_shading(cell, PURPLE)
                        for run in paragraph.runs:
                            run.bold = True
                            run.font.color.rgb = RGBColor(255, 255, 255)
                    elif row_number % 2 == 0:
                        set_cell_shading(cell, LIGHT_GREY)
            document.add_paragraph().paragraph_format.space_after = Pt(1)
            continue
        heading = re.match(r"^(#{1,3})\s+(.+)$", stripped)
        if heading:
            level = len(heading.group(1))
            text = heading.group(2)
            if level == 1 and not title_written:
                paragraph = document.add_paragraph()
                paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
                paragraph.paragraph_format.space_before = Pt(18)
                paragraph.paragraph_format.space_after = Pt(14)
                run = paragraph.add_run(text)
                run.bold = True
                run.font.name = "Aptos Display"
                run.font.size = Pt(21)
                run.font.color.rgb = RGBColor.from_string(PURPLE)
                title_written = True
            else:
                document.add_heading(text, level=level)
            index += 1
            continue
        if stripped.startswith("**") and stripped.endswith("  "):
            stripped = stripped[:-2]
        ordered = re.match(r"^(\d+)\.\s+(.+)$", stripped)
        if ordered:
            paragraph = document.add_paragraph(style="List Number")
            add_inline(paragraph, ordered.group(2))
            index += 1
            continue
        if stripped.startswith("- "):
            paragraph = document.add_paragraph(style="List Bullet")
            add_inline(paragraph, stripped[2:])
            index += 1
            continue
        if set(stripped) == {"_"}:
            paragraph = document.add_paragraph("_" * 90)
            paragraph.paragraph_format.space_after = Pt(9)
            index += 1
            continue
        paragraph = document.add_paragraph()
        if stripped.startswith("**RFC status:") or stripped.startswith("**Application:") or stripped.startswith("**Prepared:") or stripped.startswith("**Specification reviewed:") or stripped.startswith("**Primary mobile scope:"):
            paragraph.paragraph_format.space_after = Pt(2)
        add_inline(paragraph, stripped.replace("  ", " "))
        index += 1

    properties = document.core_properties
    properties.title = "RFC: CSU Unified Mobile Application — Feature Coverage and Client Decisions"
    properties.subject = "Client review of covered, partial, missing and unclear CSU mobile features"
    properties.author = "CSU Mobile Development Team"
    properties.keywords = "CSU, openIMIS, Flutter, Claims, Policies, HIV, RFC"
    document.save(OUTPUT)
    print(f"Wrote {OUTPUT}")


if __name__ == "__main__":
    render()
