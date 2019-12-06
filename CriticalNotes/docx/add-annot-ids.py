'''
This script adds annotation ids (random generated uuids) to all cells in a table of a docx-document.

Required pythonmodules:
- python-docx
- python-uuid

Created on 2019-12-05
Author: tbachmann
'''

import docx
import uuid

# input file
inFile = "CN_LiaV.docx"
# output file
outFile = "CN_LiaV_out.docx"
# prefix of the annotation ids
idPrefix = "opera_annot_"
# id of annot id col (zero based index)
annotColID = 1


# open document
doc = docx.Document(inFile)

# go over all cells in the first table
for i, row in enumerate(doc.tables[0].rows):
  # first row is header
  if i < 1:
    continue
  
  # create new annot id
  annotID = idPrefix + str(uuid.uuid4())
  # write annot id to cell
  row.cells[annotColID].paragraphs[0].text = annotID
  print(j, annotID)

# write file
doc.save(outFile)