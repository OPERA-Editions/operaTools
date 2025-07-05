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
import subprocess
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
insert_spots = True
# shall the input file be reloaded?
reload_file = True


cn_path = '/Users/tbachmann/repos/opera/edition-74338567/resources/CN/'

# chose the acts
# name, gid, annot_no start, input file, output file, spot g-id, spot g-sheetid, spot-start-id, out_file_cn_tei
cn_docs = [
  # https://docs.google.com/document/d/1fVXvd_OFqcGomBztwYO6eiiWgCift6tmVrn6oZTYyDA/edit?pli=1
  # cn: https://docs.google.com/spreadsheets/d/1ttb7FSfHO9gXd450TCrRtrf3jObXwD_6mLBt52cP5e4/edit?gid=0#gid=0
  # ['I-I', '1fVXvd_OFqcGomBztwYO6eiiWgCift6tmVrn6oZTYyDA', 1, 'CN_first', 'CN_first_addedcols']
  # ['I-I', '1fVXvd_OFqcGomBztwYO6eiiWgCift6tmVrn6oZTYyDA', 1, 'CN_first_addedcols', 'CN_first_addedcols_out']
  # ['I-I', '1fVXvd_OFqcGomBztwYO6eiiWgCift6tmVrn6oZTYyDA', 1, 'CN_first', 'CN_first_addedcols_out', '/Users/tbachmann/repos/opera/edition-74338567/resources/CN/giselle_spots.csv', '1ttb7FSfHO9gXd450TCrRtrf3jObXwD_6mLBt52cP5e4', '0', 1]
  # CN_first_addedcols_out: https://docs.google.com/document/d/1rAlGi8w-uAvho8Giq_tu-YiewDIJ-ahzDfH_SBT1rXY/edit?usp=sharing
  # spots: 1ttb7FSfHO9gXd450TCrRtrf3jObXwD_6mLBt52cP5e4
  ['I-I', '1rAlGi8w-uAvho8Giq_tu-YiewDIJ-ahzDfH_SBT1rXY', 1, 'CN_first_addedcols_out', 'CN_second_out', '/Users/tbachmann/repos/opera/edition-74338567/resources/CN/giselle_spots.csv', '1ttb7FSfHO9gXd450TCrRtrf3jObXwD_6mLBt52cP5e4', '0', 1, '../edition-74338567/resources/CN/CN_Giselle.xml']
  # path-to-csv-file, spot-spreadsheet-key, spot-spreadsheet-id, spot-id-start
  # ['I-I', '1fVXvd_OFqcGomBztwYO6eiiWgCift6tmVrn6oZTYyDA', 1, 'CN_first_part2', 'CN_first_part2_dev']
  # ['I-I', '1fVXvd_OFqcGomBztwYO6eiiWgCift6tmVrn6oZTYyDA', 1, 'CN_first_part2_dev', 'CN_first_part2_dev_out']
]

# prefix of the annotation ids
# id_prefix = "opera_annot_"
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


# function to read google doc docx file and safe to disc
def get_google_spreadsheet_as_docx (spreadsheet_key, output_file):
    print('* reloading file from google docs...')
    # response = requests.get('https://docs.google.com/spreadsheet/ccc?key=' + spreadsheet_key + '&gid=' + sheet_id + '&output=csv')
    # https://docs.google.com/document/d/1fVXvd_OFqcGomBztwYO6eiiWgCift6tmVrn6oZTYyDA/edit
    # https://docs.google.com/document/d/1fVXvd_OFqcGomBztwYO6eiiWgCift6tmVrn6oZTYyDA/edit?usp=sharing
    # https://docs.google.com/document/export?format=docx&id=1fVXvd_OFqcGomBztwYO6eiiWgCift6tmVrn6oZTYyDA
    response = requests.get('https://docs.google.com/document/export?format=docx&id=' + spreadsheet_key)
    print('response:', response)
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

def get_surface_xmlid_by_n(source, n):
  surfaces = source.getElementsByTagName('surface')
  for surface in surfaces:
      surface_n = int(surface.attributes['n'].value)
      if surface_n == n:
          surface_xmlid = surface.attributes['xml:id'].value
          # print('surface_n:', surface_n)
          return surface_xmlid

def read_spots_from_file():
  print(f'* reading spot file: {spots_file}...')
  with open(spots_file, mode ='r') as file:
    csvFile = csv.reader(file)
    
    # read lines and remove unused data
    for line in csvFile:
      # break
      if line[0] == 'CN-No': continue
      # print(line)
      # spots_input.append(line[:5])
      spots_input.append(line)
  return spots_input

def recalculate_spots(spots, spot_start_id):
  """ spots_input:
  0: CN #
  1: No.
  2: spots A
  3: spots B
  4: spots C
  5: spots ME

  # transform coordinates
  spot blueprint: <siglum>, <surface-id>, <spot-id>, <top>, <left>, <breite>, <höhe>;
  sidenote: last 4 parameters will later be modified by script to <ulx>, <ulx>, <lrx>, <lry>
  * ulx = left
  * uly = top
  * lrx = left + breite
  * lry = top + höhe
  """

  spots_output = {}
  print("* recalculating spots...")
  for spots in spots_input:

    tmp = ''

    # if spots[4] == '' or spots[0] == '': continue
    if spots[0] == '': continue
    # if spots[0] != '1211': continue
    # print('   spots:', spots)
    # for s in spots:
    #   print('   ', s)
    

    # # remove spaces and trailing ';' and split
    # spot = spots[4].replace(" ", "")
    # # print ('spot:', spot)
    # if spot[-1] == ';': spot = spot[:-1]
    # spot = spot.split(';')
    spot = []
    for i in range(2, 6):
      this_spot = spots[i].replace(" ", "")
      # print('this_spot:', this_spot)
      if len(this_spot) < 10: continue
      if this_spot[-1] == ';': this_spot = this_spot[:-1]

      # split if necessary
      if ';' in this_spot:
        for split_spot in this_spot.split(';'):
          # print('split_spot:', split_spot)
          spot.append(split_spot)
      else:
        spot.append(this_spot)
      # spot.append(spots[i].replace(" ", "").split(';'))
    # print('spot:', spot)


    
    # calculate coordinates
    for i, s in enumerate(spot):
      # print('s:', s)
      this_spot = s.split(',')

      # some spots still have the placeholder for spot-no
      if len(this_spot) == 7:
        print('too long...', this_spot)
        continue

      # if one coordinate is missing, remove that spot
      if len(this_spot) == 5:
        print('too short...', this_spot)
        continue

      # print('this_spot:', this_spot)

      # add spot id
      # this_spot[2] = f'{spot_id:04d}'
      this_spot.insert(2, f'{spot_start_id:04d}')
      spot_start_id += 1

      # print('this_spot:', this_spot)

      ulx = this_spot[4]
      uly = this_spot[3]
      lrx = str(int(this_spot[4]) + int(this_spot[5]))
      lry = str(int(this_spot[3]) + int(this_spot[6]))

      this_spot[3] = ulx
      this_spot[4] = uly
      this_spot[5] = lrx
      this_spot[6] = lry

      # find surface id
      # print(this_spot[0])
      this_spot[1] = get_surface_xmlid_by_n(sources[this_spot[0]], int(this_spot[1]))
      # print('this_spot[1]:', this_spot[1])
      # print('this_spot:', ','.join(this_spot))

      if len(tmp) != 0:
        tmp += ';'
      # print('tmp:', tmp)
      tmp += ','.join(this_spot)
      # print('spots_output[-1]:', spots_output[-1])
    spots_output[int(spots[0])] = tmp

  # print('spots_output:', spots_output)
  return spots_output

# function to convert docx to tei via teigarage
def convert_docx_to_tei(input_file, output_file):
    convert_cmd = f"curl -X 'POST' \
        'https://teigarage.tei-c.org/ege-webservice/Conversions/docx%3Aapplication%3Avnd.openxmlformats-officedocument.wordprocessingml.document/TEI%3Atext%3Axml?properties=%3Cconversions%3E%3Cconversion%20index%3D%220%22%3E%3Cproperty%20id%3D%22oxgarage.getImages%22%3Etrue%3C%2Fproperty%3E%3Cproperty%20id%3D%22oxgarage.getOnlineImages%22%3Etrue%3C%2Fproperty%3E%3Cproperty%20id%3D%22oxgarage.lang%22%3Een%3C%2Fproperty%3E%3Cproperty%20id%3D%22oxgarage.textOnly%22%3Efalse%3C%2Fproperty%3E%3Cproperty%20id%3D%22pl.psnc.dl.ege.tei.profileNames%22%3Edefault%3C%2Fproperty%3E%3C%2Fconversion%3E%3C%2Fconversions%3E' \
        -H 'accept: application/pdf' \
        -H 'Content-Type: multipart/form-data' \
        -F 'fileToConvert=@{input_file};type=application/vnd.openxmlformats-officedocument.wordprocessingml.document'"

    result = subprocess.run(convert_cmd, shell=True, stdout=subprocess.PIPE, text=True)

    if result.returncode == 0:
        with open(output_file, 'w') as f:
            f.write(result.stdout)
    else:
        print(f'WARNING: could not convert, returncode {result.returncode}')







##### go through all acts
for cn_doc in cn_docs:
  print('processing', cn_doc)

  # TODO
  # * download file from google docs
  # * add cols
  # * add annot_no
  # * add annot_id
  # * split "No., bar, ...""
  
  ### SPOTS
  spots_file = cn_doc[5]
  spots_spreadsheet_key = cn_doc[6]
  spots_spreadsheet_sheed_id = cn_doc[7]
  spot_start_id = cn_doc[8]

  # get spots from google spreadsheet (and overwrite existing)
  if reload_spots:
    print('* reloading spots')
    get_google_spreadsheet_as_csv (spots_spreadsheet_key, spots_file, spots_spreadsheet_sheed_id)

  spots_input = []
  spots = []

  # read spot csv file
  spots_input = read_spots_from_file()
  spots_input = recalculate_spots(spots_input, spot_start_id)

  # for cnno, spot in spots_input.items():
  #   print(cnno, spot)




  input_name = cn_doc[0]
  input_file = cn_path + cn_doc[3] + '.docx'
  output_file = cn_path + cn_doc[4] + '.docx'

  # download file
  if reload_file:
    # print('* reloading file')
    # TODO: update file names / paths
    input_gid = cn_doc[1]
    input_annot_no_start = cn_doc[2]
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
  
  


  







  # iterate over rows and make changes
  print('iterate over rows...')
  for i, row in enumerate(table.rows):
    # break
    if i == 0: continue
    # print('=====', row.cells[2].text)

    # if i == 200: break
    # if i < 10: continue

    # print('CN:', row.cells[1].text)∏

    

    #### spots
    if insert_spots:
      # print('* inserting spots...')
      # print(spots_input[i])
      try:
          # actual_spot = spots_input[actual_spot_id]
          # print('spots_input[i]:', spots_input[i])
          row.cells[11].paragraphs[0].text = spots_input[i]
      except:
          # print('* no spots found for cn', i)
          pass




  # write file
  if write_output_file:
    # if DEV:
    #   print(f'* write output file: {cn_path}CN_first_dev.docx')
    #   doc.save(cn_path + 'CN_first_dev.docx')
    # else: 
    print(f'* write output file: {output_file}')
    doc.save(output_file)

  # convert to tei
  if convert_to_tei:
    # out_file_cn = cn_doc[4] + '.docx'
    print('output_file:', output_file)
    out_file_cn_tei = cn_doc[9]
    print(f'converting to TEI: {out_file_cn_tei}')
    convert_docx_to_tei(output_file, out_file_cn_tei)



print('done:')

executionTime = (time.time() - startTime)
print(f'script duration: {int(executionTime / 60)} m {int(executionTime % 60)} s {int((executionTime - int(executionTime)) * 10000)} ms')

