# import docx
import copy

from docx import Document

doc = Document('docx-table-test.docx')
tables = doc.tables
row = tables[0].rows[1]

for x in row.cells:
    print(x.text)

tr = row._tr # this is a CT_Row element

n = [copy.deepcopy(row._tr)]

# print(n)
# for x in n[0].cells:
#     print(x.text)

for new_tr in n: # build_rows should return list/iterator of CT_Row instance
    print('addnew')
    tr.addnext(new_tr)

# for new_tr in build_rows(): # build_rows should return list/iterator of CT_Row instance
#     tr.addnext(new_tr)

tr.addnext(copy.deepcopy(row._tr))

for x in tables[0].rows:
    for y in x.cells:
        print(y.text, end='  ')
    print()

doc.save('docx-table-test-output.docx')

