from datetime import date

from openpyxl import Workbook, load_workbook
from openpyxl.styles import Alignment, Font, PatternFill

from generate_csu_gap_matrix import FEATURES, ROOT


output = ROOT / 'docs/features/CSU_Features_and_APIs_Simple.xlsx'
workbook = Workbook()
sheet = workbook.active
sheet.title = 'Features and APIs'
sheet.append(['Feature', 'Current status', 'API / dependency', 'What is missing'])
for area, feature, requirement, status, current, missing, api, decision, source in FEATURES:
    sheet.append([f'{area}: {feature}', status, api, missing])

sheet.freeze_panes = 'A2'
sheet.auto_filter.ref = sheet.dimensions
sheet.sheet_view.showGridLines = False
for cell in sheet[1]:
    cell.fill = PatternFill('solid', fgColor='2F5597')
    cell.font = Font(bold=True, color='FFFFFF')
    cell.alignment = Alignment(wrap_text=True)
for column, width in zip('ABCD', (43, 19, 52, 68)):
    sheet.column_dimensions[column].width = width
colors = {'Available': 'C6E0B4', 'Compatible': 'C6E0B4', 'Partial': 'FFE699',
          'Missing': 'F4CCCC', 'Blocked': 'D9D2E9', 'Unverified': 'F4B183'}
for row in sheet.iter_rows(min_row=2):
    sheet.row_dimensions[row[0].row].height = 48
    for cell in row:
        cell.alignment = Alignment(vertical='top', wrap_text=True)
    row[1].fill = PatternFill('solid', fgColor=colors[row[1].value])

notes = workbook.create_sheet('Read me')
notes.append(['Notes'])
notes.append(['Simplified version of the existing CSU gap review.'])
notes.append([f'Exported {date.today().isoformat()}; feature statuses come from the November 12 review, not a fresh implementation audit.'])
notes.append(['An API contract needing confirmation is not proof that the backend API is missing.'])
notes.append(['No new API means the remaining work is inside the mobile application.'])
notes.column_dimensions['A'].width = 120
for row in notes:
    row[0].alignment = Alignment(wrap_text=True)
workbook.save(output)
check = load_workbook(output, read_only=True)
assert check['Features and APIs'].max_row == len(FEATURES) + 1
print(output)
print(f'{len(FEATURES)} features; 4 columns; workbook validated')
