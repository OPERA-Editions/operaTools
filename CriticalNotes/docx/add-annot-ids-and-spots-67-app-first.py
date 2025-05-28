"""This script adds
TODO
* load docx
* add annot_id
* split "No., bar, (Act, Scene; line counter), part(s)"
* safe to docx

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
# import subprocess
import copy
import re


print('=' * 40)
print('=' * 40)
startTime = time.time()



"""
TODO:
* cleanup
"""

# TODO: spot-id anpassen am ende


# shall the output file be written?
write_output_file = True
# convert the docx to TEI
convert_to_tei = True
# shall the spots be reloaded?
reload_spots = False
# shall the spots be inserted?
insert_spots = False


cn_path = '/Users/tbachmann/repos/opera/edition-74338567/resources/CN/'

# chose the acts
# 0: name, 1: gid, 2: annot_no start, 3: input file, 4: output file, [5: spot g-id, 6: spot g-sheetid, 7: spot-start-id, [8: out_file_cn_tei]]
cn_docs = [
  # https://docs.google.com/document/d/1fVXvd_OFqcGomBztwYO6eiiWgCift6tmVrn6oZTYyDA/edit?pli=1
  # cn: https://docs.google.com/spreadsheets/d/1ttb7FSfHO9gXd450TCrRtrf3jObXwD_6mLBt52cP5e4/edit?gid=0#gid=0
  # ['I-I', '1fVXvd_OFqcGomBztwYO6eiiWgCift6tmVrn6oZTYyDA', 1, 'CN_first', 'CN_first_addedcols']
  # ['I-I', '1fVXvd_OFqcGomBztwYO6eiiWgCift6tmVrn6oZTYyDA', 1, 'CN_first_addedcols', 'CN_first_addedcols_out']
  # ['Giselle CN', '1fVXvd_OFqcGomBztwYO6eiiWgCift6tmVrn6oZTYyDA', 1, 'CN_first', 'CN_first_addedcols_out', '/Users/tbachmann/repos/opera/edition-74338567/resources/CN/giselle_spots.csv', '1ttb7FSfHO9gXd450TCrRtrf3jObXwD_6mLBt52cP5e4', '0', 1],
  # TODO: Appendix
  # https://docs.google.com/document/d/1VpSQDrBFXn-spyzG8aCU-v_pKRbMHrWXQD0n9sowwoo/edit?tab=t.0
  ['Giselle CN Appendix', '1VpSQDrBFXn-spyzG8aCU-v_pKRbMHrWXQD0n9sowwoo', 1, 'CN_App_first', 'CN_App_first_addedcols_out', 'x', 'x', 'x', 1],
  # path-to-csv-file, spot-spreadsheet-key, spot-spreadsheet-id, spot-id-start
  # ['I-I', '1fVXvd_OFqcGomBztwYO6eiiWgCift6tmVrn6oZTYyDA', 1, 'CN_first_part2', 'CN_first_part2_dev']
  # ['I-I', '1fVXvd_OFqcGomBztwYO6eiiWgCift6tmVrn6oZTYyDA', 1, 'CN_first_part2_dev', 'CN_first_part2_dev_out']
]

# prefix of the annotation ids
id_prefix = "opera_annot_"
# id of annot id col (zero based index)
annot_col_id = 1

# sources
# TODO: read sources from path
source_files_path = '/Users/tbachmann/repos/opera/edition-74338567/sources/'
source_files = {
  'A': 'opera_source_af56ff93-664f-4df2-817c-5ad6d826e850.xml',
  'B': 'opera_source_c5eee823-cac3-40c6-b99f-7cde64ebee15.xml',
  'C': 'opera_source_5f7c64af-0aca-48b8-bb4f-8e5b5b1741ed.xml',
  'ME': 'opera_edition_me536d96-d5bf-422a-b155-4b8337ddf1me.xml'
}
sources = {}

for sigle, source in source_files.items():
  print(f'loading {sigle}: {source}')
  path = source_files_path + source
  # print('path: ', path)
  s = minidom.parse(source_files_path + source)
  # sources
  sources[sigle] = s


DEV = True

def add_col_at_end(table, width=3.0, header=""):
  """add a column at a end"""
  print(f'add new col: {header}, end, {width}')
  table.add_column(docx.shared.Cm(width))

  # set header
  table.columns[-1].cells[0].text = header


def add_col_at_position(table, position, width=3.0, header=""):
  """add a column at a specific position"""
  print(f'add new col: {header}, {position}, {width}')
  # print('doit!')
  # print(len(table.columns))
  table.add_column(docx.shared.Cm(width))
  # both ways work
  # table.rows[0].cells[-1].text = 'header'
  # table.columns[-1].cells[0].text = header

  # copy rows
  for col_id in range(len(table.columns)-1, position, -1):
    previous_col_id = col_id - 1
    # print('col_id:', col_id)
    # print(table.columns[col_id].width, table.columns[previous_col_id].width)

    # width
    # does not work yet...
    # print(table.columns[col_id].width, 'prev:', table.columns[previous_col_id].width)
    table.columns[col_id].width = table.columns[previous_col_id].width

    # content
    # print(len(table.column_cells(col_id)))
    for row_id, row_value in enumerate(table.columns[col_id].cells):
      # print(row_id, row_value)
      table.columns[col_id].cells[row_id].text = table.columns[previous_col_id].cells[row_id].text

  # clear "new" col
  for row_id, row_value in enumerate(table.columns[position].cells):
    table.columns[position].cells[row_id].text = ""
  # set header
  table.columns[position].cells[0].text = header

# function to read google doc docx file and safe to disc
def get_google_spreadsheet_as_docx (spreadsheet_key, output_file):
    # response = requests.get('https://docs.google.com/spreadsheet/ccc?key=' + spreadsheet_key + '&gid=' + sheet_id + '&output=csv')
    # https://docs.google.com/document/d/1fVXvd_OFqcGomBztwYO6eiiWgCift6tmVrn6oZTYyDA/edit
    # https://docs.google.com/document/d/1fVXvd_OFqcGomBztwYO6eiiWgCift6tmVrn6oZTYyDA/edit?usp=sharing
    # https://docs.google.com/document/export?format=docx&id=1fVXvd_OFqcGomBztwYO6eiiWgCift6tmVrn6oZTYyDA
    response = requests.get('https://docs.google.com/document/export?format=docx&id=' + spreadsheet_key)
    assert response.status_code == 200, 'Wrong status code'
    # response.encoding = 'utf-8'
    # spreadsheet_content = response.text

    # print(response.content)

    CHUNK_SIZE = 32768
    with open(output_file, "wb") as f:
        f.write(response.content)

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

def expand_measure_ranges (this_range):
  tmp = []
  if len(this_range) == 2:
    for x in range(int(this_range[0]), int(this_range[1]) + 1):
      tmp.append(str(x))
    return tmp
  else :
    return this_range

def get_id_from_measure(number, sigle, bar):
  # print('get_id_from_measure:', number, sigle, bar)

  # surfaces_A    = file_A   .getElementsByTagName('surface')
  # surface_xmlid = surface.attributes['xml:id'].value
  # surface_n = int(surface.attributes['n'].value)

  if sigle == 'A' and number == '' and int(bar) >= 361 and int(bar) <= 382:
    return 'edirom_measure_b01d0674-7617-4fad-ab29-937d3df03e6e'
  if sigle == 'A' and number == 'No. 18' and int(bar) >= 70 and int(bar) <= 87:
    return 'edirom_measure_b01d0674-7617-4fad-ab29-937d3df03e6e'
  if sigle == 'A' and number == 'No. 10' and int(bar) >= 120 and int(bar) <= 143:
    return 'edirom_measure_c09e558d-6d4f-4b14-b0fb-bdc703d56da9'
  if sigle == 'A' and number == 'No. 8' and int(bar) >= 189 and int(bar) <= 195:
    return 'edirom_measure_6e876961-acfa-4b86-89b4-33f5ffe5eba8 '
  if sigle == 'A' and number == 'No. 8' and int(bar) >= 157 and int(bar) <= 171:
    return 'edirom_measure_a8753609-07fd-4456-964f-1ac1550d0416'
  if sigle == 'A' and number == 'No. 7' and int(bar) >= 98 and int(bar) <= 146:
    return 'edirom_measure_fbdb5a60-ab65-4642-b338-386d5550d2c7'
  if sigle == 'A' and number == 'No. 5' and int(bar) >= 200 and int(bar) <= 215:
    return 'edirom_measure_b7a261a5-112f-6acb-a019-4d595d1a37e9'
  if sigle == 'A' and number == 'No. 5' and int(bar) >= 361 and int(bar) <= 382:
    return 'edirom_measure_b01d0674-7617-4fad-ab29-937d3df03e6e'
  if sigle == 'A' and number == 'No. 4' and int(bar) >= 96 and int(bar) <= 109:
    return 'edirom_measure_37bf059f-85c6-4167-8739-b81aa5d2c8de'
  
  extras = [
    ['A', 'No. 18', 139, 'edirom_measure_88cbf6b9-c652-4b7e-9eda-75a92df3d35b'],
    ['A', 'No. 18', 137, 'edirom_measure_77478aad-87ed-4509-9fcc-fa2e1f52f028'],
    ['A', 'No. 16', 101, 'edirom_measure_38e6f37c-13ba-4adf-8542-771650e8539a'],
    ['A', 'No. 14', 231, 'edirom_measure_dfac1f2a-3ada-49c2-bb92-ec9b98b321e7'],
    ['A', 'No. 14', 223, 'edirom_measure_dfac1f2a-3ada-49c2-bb92-ec9b98b321e7'],
    ['A', 'No. 14', 230, 'edirom_measure_411c32ca-f283-416e-bd64-770124b847e4'],
    ['A', 'No. 14', 222, 'edirom_measure_411c32ca-f283-416e-bd64-770124b847e4'],
    ['A', 'No. 14', 229, 'edirom_measure_754e2af2-89b6-44b1-ba32-147fb6d7bc96'],
    ['A', 'No. 14', 221, 'edirom_measure_754e2af2-89b6-44b1-ba32-147fb6d7bc96'],
    ['A', 'No. 14', 228, 'edirom_measure_29057523-c04d-4a67-b137-5f05a4642f5d'],
    ['A', 'No. 14', 220, 'edirom_measure_29057523-c04d-4a67-b137-5f05a4642f5d'],
    ['A', 'No. 14', 227, 'edirom_measure_848bd926-b965-4c19-a007-c9ce6d58652a'],
    ['A', 'No. 14', 219, 'edirom_measure_848bd926-b965-4c19-a007-c9ce6d58652a'],
    ['A', 'No. 14', 226, 'edirom_measure_1fb4c458-924e-4f57-8978-9d935c161bd0'],
    ['A', 'No. 14', 218, 'edirom_measure_1fb4c458-924e-4f57-8978-9d935c161bd0'],
    ['A', 'No. 14', 225, 'edirom_measure_3ade846d-eb7f-460d-b569-f64527da9782'],
    ['A', 'No. 14', 217, 'edirom_measure_3ade846d-eb7f-460d-b569-f64527da9782'],
    ['A', 'No. 14', 224, 'edirom_measure_2fd930ee-9c4d-4137-9372-fc12456b33d1'],
    ['A', 'No. 14', 216, 'edirom_measure_2fd930ee-9c4d-4137-9372-fc12456b33d1'],
    ['A', 'No. 14', 194, 'edirom_measure_264bc29a-275f-46c6-8d36-264700b2022a'],
    ['A', 'No. 14', 191, 'edirom_measure_2e0ff84b-475b-481f-b907-066ad332fc21'],
    ['A', 'No. 14', 199, 'edirom_measure_2e0ff84b-475b-481f-b907-066ad332fc21 '],
    ['A', 'No. 14', 190, 'edirom_measure_f7b9f0a4-2645-45f1-a3e4-0c2633436586'],
    ['A', 'No. 14', 192, 'edirom_measure_371fc135-dd81-47d8-aea2-300baaa841ca'],
    ['A', 'No. 14', 184, 'edirom_measure_371fc135-dd81-47d8-aea2-300baaa841ca'],
    ['A', 'No. 11', 366, 'edirom_measure_090437de-884f-42cb-bc68-dff9bd82aa4b'],
    ['A', 'No. 11', 362, 'edirom_measure_8ed78f01-e143-460e-abf7-b54aaac59199'],
    ['A', 'No. 11', 363, 'edirom_measure_9a0b0153-372c-4526-a6cc-151e301532fe'],
    ['A', 'No. 11', 218, 'edirom_measure_5810c591-4738-4e68-8aab-9db3c0421742'],
    ['A', 'No. 11', 220, 'edirom_measure_5810c591-4738-4#e68-8aab-9db3c0421742'],
    ['A', 'No. 11', 215, 'edirom_measure_dd405283-94ac-4986-b747-eafbf081e2e5'],
    ['A', 'No. 7', 186, 'edirom_measure_2dbc0e18-4c5f-459c-865a-999f2a9c1ccc'],
    ['A', 'No. 7', 184, 'edirom_measure_2dbc0e18-4c5f-459c-865a-999f2a9c1ccc'],
    ['A', 'No. 7', 185, 'edirom_measure_cc1206c6-e8cf-4e82-b635-d7bc6bf4f403'],
    ['A', 'No. 7', 183, 'edirom_measure_cc1206c6-e8cf-4e82-b635-d7bc6bf4f403'],
    ['A', 'No. 7', 178, 'edirom_measure_7a148610-cd4e-4cb2-9d2a-45d389a6875d'],
    ['A', 'No. 7', 177, 'edirom_measure_61fd6609-8d09-46ed-a1a1-a5b924b2ccaf'],
    ['A', 'No. 7', 176, 'edirom_measure_542a3bdf-f54f-4e5a-853b-adfa107e8d0a'],
    ['A', 'No. 7', 175, 'edirom_measure_da4306cd-8e1e-42e8-b81a-ed60af50d304'],
    ['A', 'No. 7', 171, 'edirom_measure_7a4ea842-0559-4ed7-9497-4d93818c13f6'],
    ['A', 'No. 5', 248, 'edirom_measure_d77a6329-a9c7-4eb8-9e80-054b47d5eb46'],
    ['A', 'No. 5', 247, 'edirom_measure_e397acf2-0544-433d-bac5-da73f4e1eb5a'],
    ['A', 'No. 5', 244, 'edirom_measure_f49b6063-8fa6-4ccf-a62d-102c7d46f664'],
    ['A', 'No. 5', 243, 'edirom_measure_0e148332-6403-4883-b192-89ae51b89461'],
    ['A', 'No. 5', 241, 'edirom_measure_e33b70ad-731e-4877-bfda-b909a4ee80a2'],
    ['A', 'No. 5', 242, 'edirom_measure_585894b2-a18d-490f-9fd4-2e8a22a028e6'],
    ['A', 'No. 4', 240, 'edirom_measure_80c23ae4-450b-41e2-b812-747f7057ce3d'],
    ['A', 'No. 4', 237, 'edirom_measure_91ddb05b-f685-4779-9e6e-9bfad735ab6a'],
  ]
  for extra in extras:
    # print(int(bar), extra[2])
    if sigle == extra[0] and number == extra[1] and int(bar) ==  extra[2]:
      return extra[3]

  this_id = ''
  for mdiv in sources[sigle].getElementsByTagName('mdiv'):
    if number in mdiv.attributes['label'].value:
      for measure in mdiv.getElementsByTagName('measure'):
        if measure.attributes['n'].value == bar:
          this_id = measure.attributes['xml:id'].value
  # print('this_id :', this_id)
  return this_id

def get_surface_xmlid_by_n(source, n):
  surfaces = source.getElementsByTagName('surface')
  for surface in surfaces:
      surface_n = int(surface.attributes['n'].value)
      if surface_n == n:
          surface_xmlid = surface.attributes['xml:id'].value
          # print('surface_n:', surface_n)
          return surface_xmlid









##### go through all acts
for cn_doc in cn_docs:
  print('processing', cn_doc)

  # TODO
  # * download file from google docs
  # * add cols
  # * add annot_no
  # * add annot_id
  # * split "No., bar, ...""
  



  input_name = cn_doc[0]
  input_gid = cn_doc[1]
  input_annot_no_start = cn_doc[2]
  input_file = cn_path + cn_doc[3] + '.docx'
  output_file = cn_path + cn_doc[4] + '.docx'

  # download file
  if not DEV or False:
    print('* downloading file from google docs')
    get_google_spreadsheet_as_docx(input_gid, input_file)


  # prefix of the annotation ids
  id_prefix = "opera_annot_"
  # id of annot id col (zero based index)
  annot_col_id = 6

  # open document
  print(f'* open file: {input_file}')
  doc = docx.Document(input_file)


  table = doc.tables[0]
  # print(table)
  
  # add new cols
  if not DEV or True:
    print('add new columns...')
    add_col_at_end(table, 3.0, 'annot_id')
    # no act & scene in giselle
    # add_col_at_end(table, 2, 3.0, 'act')
    # add_col_at_end(table, 3, 3.0, 'scene')
    add_col_at_end(table, 3.0, 'no')
    add_col_at_end(table, 1.0, 'first bar')
    add_col_at_end(table, 1.0, 'last bar')
    # add_col_at_end(table, 8, 1.0, 'first line')
    # add_col_at_end(table, 9, 1.0, 'last line')
    # add_col_at_end(table, 6, 3.0, 'system')
    add_col_at_end(table, 3.0, 'spot title')
    add_col_at_end(table, 3.0, 'spot')
    add_col_at_end(table, 18.0, 'additionalIDs')


    # add_col_at_position(table, 1, 3.0, 'annot_id')
    # # no act & scene in giselle
    # # add_col_at_position(table, 2, 3.0, 'act')
    # # add_col_at_position(table, 3, 3.0, 'scene')
    # add_col_at_position(table, 3, 3.0, 'no')
    # add_col_at_position(table, 4, 1.0, 'first bar')
    # add_col_at_position(table, 5, 1.0, 'last bar')
    # # add_col_at_position(table, 8, 1.0, 'first line')
    # # add_col_at_position(table, 9, 1.0, 'last line')
    # # add_col_at_position(table, 6, 3.0, 'system')
    # add_col_at_position(table, 7, 3.0, 'spot title')
    # add_col_at_position(table, 8, 3.0, 'spot')
    # add_col_at_position(table, 9, 3.0, 'additionalIDs')

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
  13: Category
  14: Sources
  15: AdditionalIDs
  16: Note
  17: Add. Edirom
  """
  







  # iterate over rows and make changes
  print('iterate over rows...')
  for i, row in enumerate(table.rows):
    # break
    if i == 0: continue
    # print('=====', row.cells[2].text)

    if i == 3: break
    # if i < 10: continue

    # print('CN:', row.cells[1].text)

    # add CN ID
    row.cells[0].text = str(i)

    # create new annot id
    annot_id = id_prefix + str(uuid.uuid4())
    # print('row.cells[annot_col_id]:', row.cells[annot_col_id].text)
    # row.cells[annot_col_id].paragraphs[6].text = annot_id
    row.cells[annot_col_id].text = annot_id
    
    # sources
    this_sources = row.cells[3].text
    # print('this_sources first:', this_sources)
    this_sources = re.sub(r', D \([0-9, ]*\)', '', this_sources, count=1)
    this_sources = re.sub(r', D', '', this_sources, count=1)
    this_sources = re.sub(r', E', '', this_sources, count=1)
    # print('this_sources second:', this_sources)

    this_sources = this_sources.split(', ')
    this_source = [x.strip() for x in this_sources]
    this_sources.append('ME')
    # print('this_sources:', this_sources)

    additional_ids = []

    # print('row.cells[2].text:', row.cells[2].text)


    # no_bar = copy.deepcopy(row.cells[2]).text.split(', ')  # 4x
    # print(f'no_bar ({len(no_bar)}):', no_bar)

    # no (always no_bar[0]) and row.cells[3]
    # row.cells[3].text = no_bar[0]

    # split full_name
    full_name = row.cells[1].text
    full_name_split = [x.strip() for x in full_name.split(',')]
    # print(i, full_name_split)

    # print(full_name_split[])

    this_no = full_name_split[0]
    print('this_no:', this_no)
    row.cells[7].text = this_no

    # Appendix 1, Excerpt 1 from No. 3, bars 51a–51o, Introductory Note



    # act
    if 'Introductory Note' in full_name:
      print('TODO: Introductory Note')
      row.cells[10].text = full_name
      # TODO: IN stuff
      # continue

    elif 'indication' in full_name:
      print('TODO: indication')
      row.cells[10].text = full_name
      # TODO: AI stuff
      # continue
    elif 'Title' in full_name:
      print('TODO: Title')
      row.cells[10].text = full_name
      # TODO: Title stuff
      # continue
    else:

      ##### BARS
      # full_name_split.insert(2, '42-42')
      # print('full_name_split:', full_name_split)

      # bars 1 and 5
      # bar 4
      # bars 11–12
      # bars 34‒35 and 41–42   => CN 17, 18
      # ! 'bars 34–35', '36–37 and 41–46'  => CN 19

      if len(full_name_split) > 2 and 'and' in full_name_split[2] and not '(' in full_name_split[2]:
        full_name_split[1] += ' ' + full_name_split[2]
        full_name_split.remove(full_name_split[2])
        # print('full_name_split:', full_name_split)

      bars = full_name_split[1]
      # print('bars:', bars)

      bars_split = bars.split(' ')
      # print('bars_split:', bars_split)

      # remove text element
      if 'bar' in bars_split[0]:
        bars_split.remove(bars_split[0])
      if 'and' in bars_split:
        bars_split.remove('and')
        # print('found and')


      # print('bars_split (' + str(len(bars_split)) +'):', bars_split)

      first_bar = ''
      last_bar = ''
      for this_bars in bars_split:
        # print('this_bars: ', this_bars)
        # ‒
        if '–' in this_bars:
          this_bars_split = this_bars.split('–')
        elif '‒' in this_bars:
          this_bars_split = this_bars.split('‒')
        elif '−' in this_bars:
          this_bars_split = this_bars.split('−')
        # elif '–' in this_bars:
        #   this_bars_split = this_bars.split('–')
        else:
          this_bars_split = this_bars.split('-')

        # print('this_bars_split:', this_bars_split)

        if first_bar == '':
          first_bar = this_bars_split[0]
          if len(this_bars_split) == 2:
            last_bar = this_bars_split[1]
        else:
          # print('find xmlids of measures and add to additionlIDs')
          # format: A, edirom_measure_78c642fa-4699-4bc2-a29b-f60a7d429485; A, edirom_measure_aecebcb2-8aea-4af2-a6a1-9322bc0502ba
          # <sigle>, <xml:id>

          # this_bars_split.remove(this_bars_split[1])
          # this_bars_split[1] = '14'
          this_bars_split = expand_measure_ranges(this_bars_split)

          # TODO: this_bar: add all measures, not just range
          # print('this_bars_split:', this_bars_split)

          for sigle in this_sources:
            for this_bar in this_bars_split:
              this_id = get_id_from_measure(this_no, sigle, this_bar)
              if this_id == '':
                print(f'{i}: {this_no}, {sigle}, {this_bar}')
              additional_ids.append(f'{sigle}, {this_id}')
      
      # print('first_bar:', first_bar)
      # print('last_bar:', last_bar)

      row.cells[8].text = first_bar
      row.cells[9].text = last_bar

      
      # for additional_id in additional_ids:
      #   print(additional_id)
      
      additional_ids = '; '.join(additional_ids)
      # print(additional_ids)
      row.cells[12].text = additional_ids







  # write file
  if write_output_file:
    # if DEV:
    #   print(f'* write output file: {cn_path}CN_first_dev.docx')
    #   doc.save(cn_path + 'CN_first_dev.docx')
    # else: 
    print(f'* write output file: {output_file}')
    doc.save(output_file)





print('done:')

executionTime = (time.time() - startTime)
print(f'script duration: {int(executionTime / 60)} m {int(executionTime % 60)} s {int((executionTime - int(executionTime)) * 10000)} ms')