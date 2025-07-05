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
import math
import os.path



print('=' * 40)
print('=' * 40)
startTime = time.time()



"""
TODO:
* cleanup
"""

# TODO: spot-id anpassen am ende

# shall the docx be reloaded?
always_reload_docx = False
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

# DEPR, does not work with double chars
def char_range(c1, c2):
    """Generates the characters from `c1` to `c2`, inclusive."""
    print('char_range init:', c1, c2)

    start = ord(c1[-1])
    if len(c1) > 1:
      start += 26 * len(c1) - 1

    end = ord(c2[-1])
    if len(c2) > 1:
      end += 26 * len(c2) - 1

    print('char_range: start:', start, 'end:', end)

    for c in range(start, end+1):
        print('char_range: c:', c)
        this_offset = c - start
        print('char_range: this_offset:', this_offset)
        real_offset = start + this_offset - 123

      #### TODO: hier shit fixen, wtf?
      # von 42y zu 42aa...



        print('char_range: real_offset:', real_offset)
        c = ''
        for i in range(0, math.ceil(this_offset / 26) + 1):
          print('i:', i)
          c += chr(ord(c1[i]) + real_offset)
        
        print('char_range: c:', c)
        yield c #chr(c)

# thanks ChatGPT
def custom_char_range(start: str, end: str) -> list:
    def generate_sequence():
        # Single-letter entries
        for c in range(ord('a'), ord('z') + 1):
            yield chr(c)
        # Double-letter repeating characters: aa, bb, ..., zz
        for c in range(ord('a'), ord('z') + 1):
            ch = chr(c)
            yield ch + ch

    seq = list(generate_sequence())
    start = start.lower()
    end = end.lower()

    if start not in seq or end not in seq:
        raise ValueError("Start and end must be single letters or double repeated letters (e.g., 'aa', 'bb')")

    start_index = seq.index(start)
    end_index = seq.index(end)

    step = 1 if start_index <= end_index else -1
    return seq[start_index:end_index + step:step]

def expand_measure_ranges (this_range):
  # print('expand_measure_ranges: this_range:', this_range)
  tmp = []
  if len(this_range) == 2:
    try:
      # if ints
      for x in range(int(this_range[0]), int(this_range[1]) + 1):
        # print('x:', x)
        tmp.append(str(x))
      return tmp
    except:
      # if no pure ints...
      # print(int(this_range[0][:-1]), this_range[0][-1])
      # TODO: check if double chars e.g. 88kk

      first_char = ''
      for x in this_range[0][::-1]:
        # print('x:', x)
        if not x.isdigit():
          first_char += x
        else:
          break
      second_char = ''
      for x in this_range[1][::-1]:
        # print('x:', x)
        if not x.isdigit():
          second_char += x
        else:
          break

      # print('expand_measure_ranges(): first_char:', first_char, '   second_char:', second_char)
      #for x in char_range(first_char, second_char):
      char_offset = len(first_char)
      for x in custom_char_range(first_char, second_char):
        # print('get_id_from_measure(): x:', x)
        tmp.append(this_range[0][:-char_offset] + str(x))
      return tmp
  else :
    return this_range

def get_id_from_measure(number, sigle, bar):
  print(f'get_id_from_measure: {number}, {sigle}, {bar}')

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
    ['A', 'No. 7', 153, 'edirom_measure_b723ef34-53d7-4887-b17c-b4c06416e082'],
    ['A', 'No. 7', 165, 'edirom_measure_5b871276-808f-4465-933f-02daecaa83ad'],
    ['A', 'No. 7', 169, 'edirom_measure_b723ef34-53d7-4887-b17c-b4c06416e082'],
    ['A', 'No. 11', 361, 'edirom_measure_8f23c744-49d1-427b-9b52-f12ba07b6367'],
    ['A', 'No. 11', 364, 'edirom_measure_f6eab2dc-edab-4f93-938e-527170c22973'],
    ['A', 'No. 11', 365, 'edirom_measure_430da2ba-ef3d-4da9-a6a5-6d88b610118f'],
    ['A', 'No. 11', 359, 'edirom_measure_12058364-1d2f-4179-b618-89464691a193'],
    ['A', 'No. 11', 367, 'edirom_measure_12058364-1d2f-4179-b618-89464691a193'],
    ['A', 'No. 8', 192, 'edirom_measure_6e876961-acfa-4b86-89b4-33f5ffe5eba8'], # 189-195
    ['B', 'Appendix 1 – Excerpt 8', '50t', 'edirom_measure_a5f20539-3df0-4fba-a741-ab2b7bd3489e'], # bar 44
    ['B', 'Appendix 1 – Excerpt 8', '50v', 'edirom_measure_bbabf9ea-4636-488d-b12f-775932e74191'], # bar 46
    ['B', 'Appendix 1 – Excerpt 8', '50w', 'edirom_measure_8745d763-c926-41c2-98ab-7758f26d43ef'], # bar 47
    ['B', 'Appendix 1 – Excerpt 8', '50x', 'edirom_measure_1698c657-871e-4995-9d6a-2811eafefa77'], # bar 48
    ['B', 'Appendix 1 – Excerpt 8', '50y', 'edirom_measure_48da8a2e-8160-4e6d-a911-a697e1a7c533'], # bar 49
    ['B', 'Appendix 1 – Excerpt 8', '50z', 'edirom_measure_9867ee49-c32f-4559-9f3d-1dd0b54b3350'], # bar 50
    ['B', 'Appendix 1 – Excerpt 10', '187r', 'edirom_measure_4b6a2f9a-4811-4b5e-9ef5-70e27773e908'], # bar 173
    ['B', 'Appendix 1 – Excerpt 10', '187s', 'edirom_measure_1b2edbce-65ef-48e2-ae54-52d11e3d5ff9'], # bar 174
    ['B', 'Appendix 1 – Excerpt 10', '187t', 'edirom_measure_f9d8735c-6f38-42b8-9174-46ca9fd6ef0f'], # bar 175
    ['B', 'Appendix 1 – Excerpt 10', '187u', 'edirom_measure_4d40d024-4e31-4f3d-a6c7-085571809457'], # bar 176
    ['B', 'Appendix 1 – Excerpt 10', '187v', 'edirom_measure_6759b913-79dc-46f0-99a8-def583a38d63'], # bar 177
    ['B', 'Appendix 1 – Excerpt 10', '187w', 'edirom_measure_0585d496-ed0a-43ce-8118-b35f5274ec0c'], # bar 178
    ['B', 'Appendix 1 – Excerpt 10', '187x', 'edirom_measure_b8709bde-ab15-41a7-8235-4f2e7890f9fa'], # bar 179
    ['B', 'Appendix 1 – Excerpt 10', '187y', 'edirom_measure_f46db029-9763-44c3-a076-6eafe1c8e943'], # bar 180
    ['B', 'Appendix 1 – Excerpt 10', '187z', 'edirom_measure_3a00fd86-d28e-4e37-90a6-777047eb3352'], # bar 181
    ['B', 'Appendix 1 – Excerpt 10', '187aa', 'edirom_measure_a13f05b8-e7d3-481f-905f-3e3c8428323a'], # bar 182
    ['B', 'Appendix 1 – Excerpt 10', '187bb', 'edirom_measure_6155dc37-3678-4fec-a260-ca18dd1d0c49'], # bar 183
    ['B', 'Appendix 1 – Excerpt 10', '187cc', 'edirom_measure_af13c02c-65b8-465c-aabe-00ee7554aee4'], # bar 184
    ['B', 'Appendix 1 – Excerpt 10', '187dd', 'edirom_measure_cd8f1616-9dbe-4181-8fa1-a948f1dd00d0'], # bar 185
    ['B', 'Appendix 1 – Excerpt 10', '187ee', 'edirom_measure_217d3abe-8d74-482f-984e-3c9ed0f58657'], # bar 186
    ['B', 'Appendix 1 – Excerpt 10', '187ff', 'edirom_measure_a3cd79ea-82e9-4a2b-80e3-8831ca7f8255'], # bar 187
    ['B', 'Appendix 1 – Excerpt 11', '215b', 'edirom_measure_aa97ed61-7833-47f9-92ce-1ed997a11487'], # bar 209
    ['B', 'Appendix 1 – Excerpt 11', '215d', 'edirom_measure_6ad63db5-d711-44e5-9d70-4dade1258611'], # bar 211
    ['B', 'Appendix 1 – Excerpt 11', '215e', 'edirom_measure_22fe2567-f92b-492f-85d6-ef6a9862b2d1'], # bar 212
    ['B', 'Appendix 1 – Excerpt 11', '215h', 'edirom_measure_6d1df9d8-2c71-4b81-b3e1-599c643673ee'], # bar 215
    ['B', 'Appendix 1 – Excerpt 13', '103n', 'edirom_measure_a303f20d-6dbc-40f1-851a-76009b91504a'], # bar 97
    ['B', 'Appendix 1 – Excerpt 13', '103q', 'edirom_measure_d133c029-1426-498d-90d4-5e774b1375cb'], # bar 100
    ['B', 'Appendix 1 – Excerpt 13', '103r', 'edirom_measure_b6938c95-c167-40aa-ab1c-dc226ec28cba'], # bar 101
    ['B', 'Appendix 1 – Excerpt 13', '103s', 'edirom_measure_50feb158-ee17-4311-8b90-5181799d3823'], # bar 102
    ['B', 'Appendix 1 – Excerpt 13', '103t', 'edirom_measure_aea6e0dd-bbe2-4985-a869-9ecd34d171c7'], # bar 103
    ['A', 'Appendix 5 – Supplemental Number 1', 129, 'edirom_measure_130f939a-e636-4ee2-8cce-0b9035002a76'], # bar 43
    ['A', 'Appendix 5 – Supplemental Number 1', 130, 'edirom_measure_ab28aa51-46bc-4105-84ec-eb901441b8b1'], # bar 44
    ['A', 'Appendix 5 – Supplemental Number 1', 131, 'edirom_measure_d613030e-1e12-4a3d-a3ed-a6de4bbc403a'], # bar 45
    ['A', 'Appendix 5 – Supplemental Number 1', 132, 'edirom_measure_e43c40b9-2a6a-462b-8493-385103e7794e'], # bar 46
    ['A', 'Appendix 5 – Supplemental Number 1', 133, 'edirom_measure_a70fc78a-cd8b-4502-bab5-8a19ba8a6e2e'], # bar 47
    ['A', 'Appendix 5 – Supplemental Number 1', 134, 'edirom_measure_7c600e9e-a524-4b51-b3e4-2cb60ce12e8a'], # bar 48
    ['A', 'Appendix 5 – Supplemental Number 1', 135, 'edirom_measure_38f4ff76-bc27-43a7-a83d-0e2b09b44828'], # bar 49
    ['A', 'Appendix 5 – Supplemental Number 1', 136, 'edirom_measure_9db0cc7a-5829-4d4e-811f-c510d9b677bf'], # bar 50
    ['A', 'Appendix 5 – Supplemental Number 1', 137, 'edirom_measure_ab7b8c0a-ee4b-462a-8ee4-5f1184c2fec5'], # bar 51
    ['A', 'Appendix 5 – Supplemental Number 1', 138, 'edirom_measure_a129b256-c6a7-4802-9460-fe3f18da7d55'], # bar 52
    ['A', 'Appendix 5 – Supplemental Number 1', 146, 'edirom_measure_27f71a95-6a13-4bac-9688-6d295338d26f'], # bar 60
    ['A', 'Appendix 5 – Supplemental Number 1', 149, 'edirom_measure_658f80ea-c47b-4a8f-a03d-abe5be71f4bc'], # bar 63
    ['A', 'Appendix 5 – Supplemental Number 1', 150, 'edirom_measure_671a0b34-4a0f-4d53-829d-2d3c4ee8812c'], # bar 64
    ['A', 'Appendix 5 – Supplemental Number 1', 153, 'edirom_measure_f2b99076-897e-4c28-82dc-6ab8a07ac934'], # bar 67
    ['A', 'Appendix 5 – Supplemental Number 1', 154, 'edirom_measure_35ede659-5c4e-486f-aa9f-ead5fcb7ab65'], # bar 68
    ['A', 'Appendix 5 – Supplemental Number 1', 155, 'edirom_measure_d31e423a-4895-42a0-b689-91313a522692'], # bar 69
    ['A', 'Appendix 5 – Supplemental Number 1', 156, 'edirom_measure_8b26690d-ee19-4fcd-bc5d-3857aed8ca5d'], # bar 70
    ['A', 'Appendix 5 – Supplemental Number 1', 157, 'edirom_measure_3bea2941-f1e0-44fe-8a92-3c9f794c60f1'], # bar 71
    ['A', 'Appendix 5 – Supplemental Number 1', 158, 'edirom_measure_3bea2941-f1e0-44fe-8a92-3c9f794c60f1'], # bar 72
    ['A', 'Appendix 5 – Supplemental Number 1', 159, 'edirom_measure_5f8d69af-eaab-4bd3-be56-ed3651aeff86'], # bar 73
    ['A', 'Appendix 5 – Supplemental Number 1', 160, 'edirom_measure_090113a6-35d1-4fbb-be38-5d0c7d09a1c9'], # bar 74
    ['A', 'Appendix 5 – Supplemental Number 1', 161, 'edirom_measure_1f7c0fd6-2be4-4100-a943-fe4b86a12636'], # bar 75
    ['A', 'Appendix 5 – Supplemental Number 1', 162, 'edirom_measure_cc00cfb0-5fea-49b3-8a9c-c00c64eb5bd6'], # bar 76

    ['B', 'Appendix 5 – Supplemental Number 1', 129, 'edirom_measure_99d3cf31-ef55-452b-805f-46c156d5219b'], # bar 43
    ['B', 'Appendix 5 – Supplemental Number 1', 130, 'edirom_measure_c944cff9-b274-46e1-a345-083ae5dbdd1f'], # bar 44
    ['B', 'Appendix 5 – Supplemental Number 1', 131, 'edirom_measure_b179c75f-d75a-45c1-9465-ddb2beab84c2'], # bar 45
    ['B', 'Appendix 5 – Supplemental Number 1', 132, 'edirom_measure_2f5bd901-23f8-4db1-a6c1-c0334c6dbbe9'], # bar 46
    ['B', 'Appendix 5 – Supplemental Number 1', 133, 'edirom_measure_ba32e610-3851-4e2b-8c47-939369d9535d'], # bar 47
    ['B', 'Appendix 5 – Supplemental Number 1', 134, 'edirom_measure_ac895018-3c79-4e3a-ae4b-e49e4b368159'], # bar 48
    ['B', 'Appendix 5 – Supplemental Number 1', 135, 'edirom_measure_3960cdba-94ec-4182-984e-8e031a56a59b'], # bar 49
    ['B', 'Appendix 5 – Supplemental Number 1', 136, 'edirom_measure_0c8a4b46-4c58-453b-9769-74e46286a162'], # bar 50
    ['B', 'Appendix 5 – Supplemental Number 1', 137, 'edirom_measure_26b50950-e859-410b-be23-dd24c5713cbd'], # bar 51
    ['B', 'Appendix 5 – Supplemental Number 1', 138, 'edirom_measure_4e893a43-07d8-4d95-91ba-044ff88ec01b'], # bar 52
    ['B', 'Appendix 5 – Supplemental Number 1', 146, 'edirom_measure_52eca378-62ab-45a3-ba36-dec9ed8a6b77'], # bar 60
    ['B', 'Appendix 5 – Supplemental Number 1', 149, 'edirom_measure_168840fb-60c2-47e9-a643-904928112f25'], # bar 63
    ['B', 'Appendix 5 – Supplemental Number 1', 150, 'edirom_measure_8cff130c-8f7e-4a3e-92db-586328708b21'], # bar 64
    ['B', 'Appendix 5 – Supplemental Number 1', 153, 'edirom_measure_31352822-f968-4b16-bf1e-587242b4f7a7'], # bar 67
    ['B', 'Appendix 5 – Supplemental Number 1', 154, 'edirom_measure_63adff29-c7b5-45b2-b7d5-e2f3b4e45300'], # bar 68
    ['B', 'Appendix 5 – Supplemental Number 1', 155, 'edirom_measure_c702fe9a-c54b-4e8c-b020-1d1fbc97b59c'], # bar 69
    ['B', 'Appendix 5 – Supplemental Number 1', 156, 'edirom_measure_3dbfe2cf-18a3-4349-9439-6c999872d15d'], # bar 70
    ['B', 'Appendix 5 – Supplemental Number 1', 157, 'edirom_measure_3cecbb27-1c3e-4b1e-97ec-4e98bd06a664'], # bar 71
    ['B', 'Appendix 5 – Supplemental Number 1', 158, 'edirom_measure_e95e032a-effd-433e-abe0-ba1140f8b63d'], # bar 72
    ['B', 'Appendix 5 – Supplemental Number 1', 159, 'edirom_measure_46129a72-b13b-4c06-a1bd-fdaaba776556'], # bar 73
    ['B', 'Appendix 5 – Supplemental Number 1', 160, 'edirom_measure_9f7e4a52-d0f5-42d2-abbb-dcf1872a88d6'], # bar 74
    ['B', 'Appendix 5 – Supplemental Number 1', 161, 'edirom_measure_4861c012-1995-4532-8847-cf6fa070b988'], # bar 75
    ['B', 'Appendix 5 – Supplemental Number 1', 162, 'edirom_measure_3ebcd2b8-4702-4916-b5c1-fb34ae82f1fc'], # bar 76
    # ['A', 'Appendix 1 – Excerpt 2', 88, 'edirom_measure_d1a40f2f-c28e-44db-890f-baa4218bc6a1'], # bar 88 (non-app)
    # ['ME', 'Appendix 1 – Excerpt 2', 88, 'opera_measure_4fe50dee-2033-4a74-a82e-0968bd3ffe76'], # bar 88 (non-app)
  ]
  for extra in extras:
    # print(int(bar), extra[2])
    try:
      # this is nonsense lol
      bar = int(bar)
    except: pass
    if sigle == extra[0] and number == extra[1] and str(bar) == str(extra[2]):
      # print('found extra:', extra[3])
      return extra[3]

  this_id = ''
  for mdiv in sources[sigle].getElementsByTagName('mdiv'):
    if number in mdiv.attributes['label'].value:
      # print('number:', number)
      for measure in mdiv.getElementsByTagName('measure'):
        if measure.attributes['n'].value == str(bar):
          # print('measure:', measure.attributes['n'].value)
          this_id = measure.attributes['xml:id'].value
  # print('get_id_from_measure(): this_id :', this_id)
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

  # check if input docx exists, then check if always_reload_docx, else download file
  if not os.path.isfile(input_file) or always_reload_docx:
    print('* downloading file from google docs')
    get_google_spreadsheet_as_docx(input_gid, input_file)
  else:
    print('* input file already exists, no download needed:', input_file)
  


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

    # if i < 343: continue
    # if i > 343: break

    print(f'=== CN {i}:', row.cells[1].text)

    # add CN ID
    row.cells[0].text = str(i)

    # create new annot id
    annot_id = id_prefix + str(uuid.uuid4())
    # print('row.cells[annot_col_id]:', row.cells[annot_col_id].text)
    # row.cells[annot_col_id].paragraphs[6].text = annot_id
    row.cells[annot_col_id].text = annot_id
    
    # sources
    this_sources = row.cells[3].text
    print('this_sources first:', this_sources)
    this_sources = re.sub(r'D \([0-9,–‒ ]*\)', '', this_sources, count=1)
    this_sources = re.sub(r'D', '', this_sources, count=1)
    this_sources = re.sub(r'E', '', this_sources, count=1)
    this_sources = re.sub(r'F', '', this_sources, count=1)
    this_sources = re.sub(r'M \([0-9,–‒ ]*\)', '', this_sources, count=1)
    print('this_sources second:', this_sources)


    this_sources = this_sources.split(', ')
    this_sources = [x.strip() for x in this_sources if x.strip() != '']
    # ME Appendix will come later...
    this_sources.append('ME')
    print('this_sources:', this_sources)

    additional_ids = []

    # print('row.cells[2].text:', row.cells[2].text)


    # no_bar = copy.deepcopy(row.cells[2]).text.split(', ')  # 4x
    # print(f'no_bar ({len(no_bar)}):', no_bar)

    # no (always no_bar[0]) and row.cells[3]
    # row.cells[3].text = no_bar[0]

    full_name = row.cells[1].text


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


    # CN ... 114, 132, 162, 164, 168, 186, 187
    elif  'Appendix 1, Excerpt 7 from No. 8, bars 34l‒35, P. Fl., Gr. Fl., Cl. en Si flat I' in full_name:
      additional_ids = [
        'tbd',
      ]
      additional_ids = '; '.join(additional_ids)
      # print(additional_ids)
      row.cells[12].text = additional_ids
    elif  'Appendix 1, Excerpt 13 from No. 13, bars 103q‒104, Vn. I' in full_name:
      additional_ids = [
        'tbd',
      ]
      additional_ids = '; '.join(additional_ids)
      # print(additional_ids)
      row.cells[12].text = additional_ids
    elif      'Appendix 1, Excerpt 13 from No. 13, bars 103r‒104, Vn. II' in full_name:
      additional_ids = [
        'tbd',
      ]
      additional_ids = '; '.join(additional_ids)
      # print(additional_ids)
      row.cells[12].text = additional_ids
    elif      'Appendix 1, Excerpt 16 from No. 17, bars 176–177a, 177g–178, Gr. Fl.' in full_name:
      additional_ids = [
        'tbd',
      ]
      additional_ids = '; '.join(additional_ids)
      # print(additional_ids)
      row.cells[12].text = additional_ids
    elif      'Appendix 1, Excerpt 16 from No. 17, bars 173–174, 177–177a, 177d–177e and 178–179, Bn. I' in full_name:
      additional_ids = [
        'tbd',
      ]
      additional_ids = '; '.join(additional_ids)
      # print(additional_ids)
      row.cells[12].text = additional_ids
    elif      'Appendix 1, Excerpt 20 from No. 19, bars 124e–125, Cor en Mi flat I/II' in full_name:
      additional_ids = [
        'tbd',
      ]
      additional_ids = '; '.join(additional_ids)
      # print(additional_ids)
      row.cells[12].text = additional_ids
    elif      'Appendix 1, Excerpt 20 from No. 19, bars 124l–125, Cl. en Si flat I/II' in full_name:
      additional_ids = [
        'tbd',
      ]
      additional_ids = '; '.join(additional_ids)
      # print(additional_ids)
      row.cells[12].text = additional_ids
    elif      'Appendix 1, Excerpt 20 from No. 19, bars 124m–125, Hb. I/II' in full_name:
      additional_ids = [
        'tbd',
      ]
      additional_ids = '; '.join(additional_ids)
      # print(additional_ids)
      row.cells[12].text = additional_ids
    elif      'Appendix 1, Excerpt 22 from No. 20, bars 78j‒79, Cor en Fa I/II' in full_name:
      additional_ids = [
        'tbd',
      ]
      additional_ids = '; '.join(additional_ids)
      # print(additional_ids)
      row.cells[12].text = additional_ids
    elif      'Appendix 1, Excerpt 22 from No. 20, bars 78k–79, Cl. en Ut I/II' in full_name:
      additional_ids = [
        'tbd',
      ]
      additional_ids = '; '.join(additional_ids)
      # print(additional_ids)
      row.cells[12].text = additional_ids
    elif      'Appendix 1, Excerpt 22 from No. 20, bars 78o–79, Gr. Fl.' in full_name:
      additional_ids = [
        'tbd',
      ]
      additional_ids = '; '.join(additional_ids)
      # print(additional_ids)
      row.cells[12].text = additional_ids


      # print('TODO: make spots for CN', i)
      # row.cells[10].text = full_name
    else:
      # split full_name
      full_name_split = [x.strip() for x in full_name.split(',')]
      print(i, full_name_split)

      # print(full_name_split[])

      # Appendix 1, Excerpt 1 from No. 3, bars 51a–51o, Introductory Note
      # -> Appendix 1 – Excerpt 1
      # Appendix 1, Excerpt 24 from No. 20, bar 117d, Oph.
      # -> Appendix 1 – Excerpt 24
      # Appendix 2, Ossia 1 in No. 7 Marche, bars 58–97, Introductory Note
      # -> Appendix 2 – Ossia 1
      # Appendix 2, Ossia 1 in No. 7, bars 58, P. Fl., Gr. Fl., Hb. I, Cl. en Ut I
      # -> Appendix 2 – Ossia 1
      # Appendix 5, Supplemental Number 1, bar 112, Gr. Fl.
      # -> Appendix 5 – Supplemental Number 1

      this_no = full_name_split[0]
      print('this_no:', this_no)
      try:
        excerpt = re.findall("Excerpt [0-9]*", full_name_split[1])[0]
        if excerpt !='':
          this_no += ' – ' + excerpt
      except:
        pass
      
      try:
        ossia = re.findall("Ossia [0-9]*", full_name_split[1])[0]
        if ossia !='':
          this_no += ' – ' + ossia
      except:
        pass

      try:
        supplemental = re.findall("Supplemental Number [0-9]*", full_name_split[1])[0]
        if supplemental !='':
          this_no += ' – ' + supplemental
      except:
        pass





      print('this_no:', this_no)
      row.cells[7].text = this_no






      ##### BARS
      # full_name_split.insert(2, '42-42')
      # print('full_name_split:', full_name_split)

      # bars 1 and 5
      # bar 4
      # bars 11–12
      # bars 34‒35 and 41–42   => CN 17, 18
      # ! 'bars 34–35', '36–37 and 41–46'  => CN 19

      # CN 14: Appendix 1, Excerpt 3 from No. 3, bars 88d‒88e, 88f‒88g and 88m‒88n, Hb. II

      # print('full_name_split:', full_name_split)
      bars_raw = []
      for bar in full_name_split[2:]:
        # print('-bar:', bar)
        if 'and' in bar:
          # print('found and:', bar)
          bars_raw = full_name_split[2:full_name_split.index(bar)+1]
          break
      if len(bars_raw) == 0:
        bars_raw = [full_name_split[2]]
      # print('bars_raw:', bars_raw)

      # remove bar/s in first element
      if 'bars' in bars_raw[0]:
        bars_raw[0] = bars_raw[0].replace('bars', '').strip()
      if 'bar' in bars_raw[0]:
        bars_raw[0] = bars_raw[0].replace('bar', '').strip()
      # print('bars_raw:', bars_raw)

      # expand last element if contains 'and'
      if 'and' in bars_raw[-1]:
        both_lasts = bars_raw[-1].split(' and ')
        bars_raw[-1] = both_lasts[0].strip()
        bars_raw.append(both_lasts[1].strip())
      # print('bars_raw:', bars_raw)
      bars_split = bars_raw

      # try:
      #   if len(full_name_split) > 2 and 'and' in full_name_split[3] and not '(' in full_name_split[3]:
      #     full_name_split[2] += ' ' + full_name_split[3]
      #     full_name_split.remove(full_name_split[3])
      #     print('full_name_split:', full_name_split)
      # except:
      #   pass
      # bars = full_name_split[2]
      # print('bars:', bars)

      # bars_split = bars.split(' ')
      # # print('bars_split:', bars_split)

      # # remove text element
      # if 'bar' in bars_split[0]:
      #   bars_split.remove(bars_split[0])
      # if 'and' in bars_split:
      #   bars_split.remove('and')
      #   print('found and')


      print('bars_split (' + str(len(bars_split)) +'):', bars_split)

      first_bar = ''
      last_bar = ''
      for this_bars in bars_split:
        print('this_bars: ', this_bars)
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

        print('this_bars_split:', this_bars_split)

        if first_bar == '' and False:
          first_bar = this_bars_split[0]
          if len(this_bars_split) == 2:
            last_bar = this_bars_split[1]
        else:
          print('find xmlids of measures and add to additionlIDs')
          # format: A, edirom_measure_78c642fa-4699-4bc2-a29b-f60a7d429485; A, edirom_measure_aecebcb2-8aea-4af2-a6a1-9322bc0502ba
          # <sigle>, <xml:id>

          # this_bars_split.remove(this_bars_split[1])
          # this_bars_split[1] = '14'
          this_bars_split = expand_measure_ranges(this_bars_split)
          # TODO: this_bar: add all measures, not just range
          print('this_bars_split (after expand_measure_ranges()):', this_bars_split)

          for sigle in this_sources:
            for this_bar in this_bars_split:
              this_id = get_id_from_measure(this_no, sigle, this_bar)
              if this_id == '':
                print(f'WARNING: not found: CN{i}: {this_no}, {sigle}, {this_bar}')
              additional_ids.append(f'{sigle}, {this_id}')
      
      # print('first_bar:', first_bar)
      # print('last_bar:', last_bar)

      row.cells[8].text = first_bar
      row.cells[9].text = last_bar

      print('additional_ids:')
      for additional_id in additional_ids:
        print(additional_id)
      
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