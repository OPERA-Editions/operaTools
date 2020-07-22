'''
This script finds all the cells with only one First bar from the given list of IDs.

Required pythonmodules:
- python-docx

Created on 2019-12-05
Author: tbachmann
'''
import docx

# input file
inFile = '../../../edition-74338558/Resources/CN/CN_LiaV.docx'
# input file with ids
inFileIDs = 'separate-ids.txt'



doc = docx.Document(inFile)
thisTable = doc.tables[0]

# read IDs
IDs = []
with open(inFileIDs, 'r') as f:
    for line in f:
        IDs.append(int(line))
print(IDs)

for ID in IDs:
    cells = thisTable.rows[ID].cells
    annot_id = cells[1].text
    firstBarCell = cells[4].text
    if len(firstBarCell) == 0:
        continue
    thisFirstBars = list(map(int, firstBarCell.split(',')))
    # print('thisFirstBars:', thisFirstBars)
    if len(thisFirstBars) > 1:
        continue
    print("Ldf.No: {}, annot_id: {}".format(ID, annot_id))


# for i, row in enumerate(thisTable.rows):
#     # print('i:', i)
#     firstBarCell = row.cells[4].text
#     if len(firstBarCell) == 0:
#         continue
    
#     bars = firstBarCell.split(',')
#     if len(bars) > 1:
#         annotID = row.cells[1].text
#         print('Multiple first Bars in Lfd.No: {} ({})'.format(i, annotID))
print('done')