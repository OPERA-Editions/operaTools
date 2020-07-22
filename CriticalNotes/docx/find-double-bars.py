'''
This script finds First bar cells in CN-Table with more than one bar.

Required pythonmodules:
- python-docx

Created on 2019-12-10
Author: tbachmann
'''
import docx

# input file
inFile = "CN_LiaV-crs.docx"

doc = docx.Document(inFile)
thisTable = doc.tables[0]

for i, row in enumerate(thisTable.rows):
    # print('i:', i)
    firstBarCell = row.cells[4].text
    if len(firstBarCell) == 0:
        continue
    
    bars = firstBarCell.split(',')
    if len(bars) > 1:
        annotID = row.cells[1].text
        print('Multiple first Bars in Lfd.No: {} ({})'.format(i, annotID))
print('done')