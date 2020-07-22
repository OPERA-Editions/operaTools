'''
This script checks if an annot_id is used more than once.

Required pythonmodules:
- python-docx

Created on 2019-12-10
Author: tbachmann
'''
import docx

# input file
inFile = "../../../edition-74338558/Resources/CN/CN_LiaV.docx"
# id of annot id col (zero based index)
annotColID = 1


print("Checking annot_ids for doubles...")
# open document
doc = docx.Document(inFile)

doubles = []
annotIDs = []
# go over all cells in the first table
for i, row in enumerate(doc.tables[0].rows):
    # first row is header
    if i < 1 :
        continue
  
    thisAnnotID = row.cells[annotColID].paragraphs[0].text

    if thisAnnotID == "":
        print("no annot_id in l.{}".format(i))

    if thisAnnotID in annotIDs:
        print("double annot_id (l.{}): ".format(i), thisAnnotID)
        doubles.append(thisAnnotID)
    else:
        annotIDs.append(thisAnnotID)

if len(doubles) == 0:
    print("No doubles found.")