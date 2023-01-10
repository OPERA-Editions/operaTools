"""This script adds
- CN No.
- annotation ids (random generated uuids)
- spots
  - find surface ids (@xml:id) by page (@n)
  - recalculate coordinates
  - generate spot IDs
- TODO split No. and Full name if necessary
to all cells in a table of a docx-document.

Required pythonmodules:
- python-docx
- python-uuid
- ...

Created on 2019-12-05
Author: tbachmann
updated 2022-06-15 by tbachmann: add spots
"""

import docx
import uuid
import csv
from xml.dom import minidom
import requests

import time
startTime = time.time()


# shall the output file be written?
write_output_file = True
# shall the spots be reloaded?
reload_spots = True


act = 'I-I'
# act = 'I-II'
# act = 'II'
# act = 'III'

# input file
if act == 'I-I':
  in_file_cn = "../edition-74338566/resources/CN/CN TE/Steffani-CN_TE-nospots.docx"
  out_file_cn = "../edition-74338566/resources/CN/CN TE/Steffani-CN_TE.docx"
  spreadsheet_sheet_id = '0'
  in_file_spots = "../edition-74338566/resources/CN/CN TE/Steffani_CN_TE-spots.csv"
  

# prefix of the annotation ids
id_prefix = "opera_annot_"
# id of annot id col (zero based index)
annot_col_id = 1

# key of google spreadsheet (gid entered later)
spreadsheet_key = '1Yvi0XnkenYdU6GBQzpvsu8THBEpRONA1MJBU2RS75fk'



# function to read google doc csv file and safe to disc
def get_google_spreadsheet_as_csv (spreadsheet_key, output_file, sheet_id):
    response = requests.get('https://docs.google.com/spreadsheet/ccc?key=' + spreadsheet_key + '&gid=' + sheet_id + '&output=csv')
    assert response.status_code == 200, 'Wrong status code'
    response.encoding = 'utf-8'
    spreadsheet_content = response.text

    csv_response = csv.reader(spreadsheet_content.splitlines(), delimiter=',')
    csv_list = list(csv_response)

    with open(output_file, 'w') as csv_file:
        # creating a csv writer object  
        csv_writer = csv.writer(csv_file)

        # writing the data rows  
        csv_writer.writerows(csv_list)



"""spots_input:
0: CN #
1: Act
2: Sc.
3: No.
4: spots (<siglum>, <surface-id>, <spot-id>, <top>, <left>, <breite>, <höhe>;)
5...: not used notes
"""

# get spots from google spreadsheet (and overwrite existing)
if reload_spots:
  print('* reloading spots for ' + act)
  get_google_spreadsheet_as_csv (spreadsheet_key, in_file_spots, spreadsheet_sheet_id)



spots_input = []
spots = []

# read spot csv file
print(f'* reading spot file: {in_file_spots}...')
with open(in_file_spots, mode ='r') as file:
  csvFile = csv.reader(file)

  # read lines and remove unused data
  for line in csvFile:
    if line[0] == 'CN-No': continue
    # print(line)
    spots_input.append(line[:5])


# XML-Stuff to find surface IDs
# parse source files
print('* parsing sourcefiles...')
file_T_TE    = minidom.parse('../edition-74338566/sources/opera_source_e12fba06-b908-42db-9442-c2c8d0075fbc.xml')

# get surfaces of sources
surfaces_T_TE    = file_T_TE   .getElementsByTagName('surface')

def get_surface_xmlid_by_n(source, n):
    # print(source)
    if source == 'T-TE':
        surfaces = surfaces_T_TE
    else:
      print('ERROR: invalid source siglum')

    for surface in surfaces:
        surface_xmlid = surface.attributes['xml:id'].value
        # surface_n = int(surface.attributes['n'].value)
        surface_n = surface.attributes['n'].value
        if surface_n == n:
            # print(surface_n)
            return surface_xmlid






# transform coordinates
"""
spot blueprint: <siglum>, <surface-id>, <spot-id>, <top>, <left>, <breite>, <höhe>;
sidenote: last 4 parameters will later be modified by script to <ulx>, <ulx>, <lrx>, <lry>
* ulx = left
* uly = top
* lrx = left + breite
* lry = top + höhe
"""
# adjust spot_id to starting id of spot
if act == 'I-I':
  spot_id = 1

print("* recalculating spots...")
for spots in spots_input:
  # print('   ', spots)
  if spots[4] == '' or spots[0] == '': continue

  # remove spaces and trailing ';' and split
  spot = spots[4].replace(" ", "")
  # print ('spot:', spot)
  if spot[-1] == ';': spot = spot[:-1]
  spot = spot.replace('T(TE)', 'T-TE')
  spot = spot.split(';')
  # print(spot)

  # calculate coordinates
  for i, s in enumerate(spot):
    spot[i] = s.split(',')
    # print(spot[i])

    ulx = spot[i][4]
    uly = spot[i][3]
    lrx = str(int(spot[i][4]) + int(spot[i][5]))
    lry = str(int(spot[i][3]) + int(spot[i][6]))

    spot[i][3] = ulx
    spot[i][4] = uly
    spot[i][5] = lrx
    spot[i][6] = lry

    # add spot id
    spot[i][2] = f'{spot_id:04d}'
    spot_id += 1

    # find surface id
    # print(spot[i][0])
    # spot[i][1] = get_surface_xmlid_by_n(spot[i][0], int(spot[i][1]))
    spot[i][1] = get_surface_xmlid_by_n(spot[i][0], spot[i][1])

    spot[i] = ','.join(spot[i])

  spots[4] = ';'.join(spot)
  # print(spot)
  # print(spots)


  #break

# print('')
# print('')
# for cn in spots_input:
#   print(cn)
# # print(spots_input[0])



# open document
print(f'* open file: {in_file_cn}')
doc = docx.Document(in_file_cn)



# go over all cells in the first table
"""CN table IDs
NOTE: id may chance, cause of word fuckup (?); check before running
 0: CN No.
 1: Annot-ID
 2: Act
 3: Scene
 4: No.
 5: fullname
 6: first bar
 7: last bar
 8: first line
 9: last line
10: System
11: spot title
12: spot
13: Sources
14: AdditionalIDs
15: Category
16: Note
17: Add. Edirom
"""
"""
     0: CN No.
     1: Annot-ID
     2: Act
     3: Scene
     4: No.
     5: Full name
     6: first bar
     7: last bar
     8: last bar
     9: first line
    10: last line
    11: System
    12: spot title
    13: spot
    14: Sources
    15: AdditionalIDs
    16: Category
    17: Note
    18: Add. Edirom
"""
actual_spot_id = 0
last_no = ''
last_name = ''
print("* iterating CN and adding annot_id, spots and split No. ...")
for i, row in enumerate(doc.tables[0].rows):
  # first row is header
  if i < 1: continue
  # if i < 145: continue
  # if i == 22: break
  
  # create new annot id
  # annot_id = id_prefix + str(uuid.uuid4())

  # CN No.
  cn_no = i
  # row.cells[0].paragraphs[0].text = str(cn_no)
  print('CN No:', cn_no)

  
  # annot-id
  # row.cells[annot_col_id].paragraphs[0].text = annot_id

  # # reformat lines
  # first_line = row.cells[6].paragraphs[0].text
  # # print(f'__{first_line}__')
  # try:
  #   if first_line != '':
  #     first_line_int = int(first_line)
  #     row.cells[6].paragraphs[0].text = str(first_line_int)
  # except:
  #   pass

  # last_line = row.cells[7].paragraphs[0].text
  # # print(f'__{last_line}__')
  # try:
  #   if last_line != '':
  #     last_line_int = int(last_line)
  #     row.cells[7].paragraphs[0].text = str(last_line_int)
  # except:
  #   pass

  # add TE to sources
  # row.cells[11].paragraphs[0].text = 'T-TE, TextEdition'

  # # additional IDs
  # if 'xml:id' in row.cells[15].paragraphs[0].text:
  #   # print('Additional ID')
  #   additionalID = 'TextEdition, ' + row.cells[15].paragraphs[0].text[len('xml:id= '):].replace(' ', '')
  #   # print(additionalID)
  #   row.cells[13].paragraphs[0].text = additionalID

  # spots
  try:
      actual_spot = spots_input[actual_spot_id]
  except:
      # TODO: after last spot error will be thrown...
      print(f'WARNING: could not find spot actual_spot_id: {actual_spot_id}')
  # print(actual_spot)
  if int(actual_spot[0]) == cn_no:
    # NOTE: check id
    # print(actual_spot)
    row.cells[10].paragraphs[0].text = actual_spot[4]
    actual_spot_id += 1

  # # split No and Full name if necessary
  # # NOTE: check id
  # this_no = row.cells[4].text.strip()
  # this_name = row.cells[5].text.strip()
  # print(i, this_no, '---', this_name)
  # if this_no == last_no:
  #   print("same")
  #   row.cells[5].paragraphs[0].text = last_name
  # elif this_no[:4] == "No. ":
  #   no = this_no.split(" ")
  #   print('new no: ', end='')
  #   print(no)
  #   last_no = no[0] + " " + no[1]
  #   last_name = " ".join(no[2:])
  #   print(last_name)
  #   row.cells[4].paragraphs[0].text = last_no
  #   row.cells[5].paragraphs[0].text = last_name
  


  # verbose
  # print(i, annot_id)
  # for i, c in enumerate(row.cells):
  #   print(f'    {i:2d}:', c.paragraphs[0].text)


# write file
if write_output_file:
  print('write output file...')
  doc.save(out_file_cn)

executionTime = (time.time() - startTime)
print(f'script duration: {int(executionTime / 60)} m {int(executionTime % 60)} s {int((executionTime - int(executionTime)) * 10000)} ms')