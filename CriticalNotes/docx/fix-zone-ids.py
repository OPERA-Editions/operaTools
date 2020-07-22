'''
This script fixes the ids of the spots in a docx containing a CN-table.

Required pythonmodules:
- python-docx

Created on 2019-12-05
Author: tbachmann
'''
import docx

# input file
inFile = "CN_LiaV.docx"
# output file
outFile = "CN_LiaV_out.docx"
# first spot id
spotID = 1
# id of col containing spots
spotColID = 12


# helper function to delete all paragraphs in a cell
def delete_paragraph(paragraph):
    p = paragraph._element
    p.getparent().remove(p)
    p._p = p._element = None

# open document
doc = docx.Document(inFile)

# go over all cells in the first table
for i, row in enumerate(doc.tables[0].rows):
  # first row is table header
  if i < 1:
    continue
  print ('row:', i)

  cell = row.cells[spotColID]

  # nothing to do if cell is empty
  if len(cell.paragraphs[0].text) < 1:
    # print('empty, continue')
    continue
  # cell.add_paragraph(str(id))
  
  spots = ""
  # get content of all paragraphs in cell and remove spaces
  for para in cell.paragraphs:
    spots += para.text.replace(" ", "")
    
  # separate spots
  spots = spots.split(";")
    
  # separate values of spots
  for i, spot in enumerate(spots):
    spots[i] = spot.split(',')

  # add new ids for spots
  for spot in spots:
    spot[2] = '{:04d}'.format(spotID)
    spotID = spotID + 1
    
  # reformat data
  cellSpotsNew = ""
  for spot in spots:
    spotAll = ""
    for s in spot:
      spotAll = spotAll + s + ', '
    # remove last ', '
    spotAll = spotAll[:-2]
    cellSpotsNew += spotAll + '; '
  # remove last '; '
  cellSpotsNew = cellSpotsNew[:-2]

  # remove old paragraphs in cells and write new one
  for para in cell.paragraphs:
    delete_paragraph(para)
  cell.add_paragraph(cellSpotsNew)

  for spot in spots:
    print(spot)

# write to file
doc.save(outFile)
