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


"""
TODO:
* cleanup
"""

# TODO: spot-id anpassen am ende


# shall the output file be written?
write_output_file = True

# act = 'I-I'
# act = 'I-II'
# act = 'II'
# act = 'III'

# chose the acts
acts = ['I-I']
acts = ['I-II']
acts = ['II']
acts = ['III']
acts = ['I-I', 'I-II', 'II', 'III']


for act in acts:
  print('processing', act)
  # input file
  #in_file_cn = "../../../edition-74338566/resources/CN/Critical_Notes_Akt-I_Anteil-CS.docx"
  # in_file_cn = "../edition-74338566/resources/CN/Critical Notes_Akt-II_CS_end_2022-IV-22_numbers_addcols.docx"
  #in_file_cn = "../edition-74338566/resources/CN/ME CN final/Critical Notes_Akt-I_Anteil-CS_2022-III-17_korrAH_2022-VIII-30_finalCS_2022-VIII-31_numbers_links_addcols.docx"
  if act == 'I-I':
    # in_file_cn = "../edition-74338566/resources/CN/ME CN final/Critical Notes_Akt-I_Anteil-MGi_Red_CS_Korr_MGi_2019-XI-05_red_SB_2022-IX-14-final_addcols_links_spotcleanup.docx"
    # in_file_cn = "../edition-74338566/resources/CN/ME CN final/2022-11-01_Critical Notes_Akt-I_Anteil-MGi_Red_CS_Korr_MGi_2019-XI-05_red_SB_2022-IX-14-final_addcols_links_spotcleanup_numbers-annotid.docx"
    # 2022-11-01_Critical Notes_Akt-I_Anteil-MGi_Red_CS_Korr_MGi_2019-XI-05_red_SB_2022-IX-14-final_addcols_links_spotcleanup_numbers-annotid.docx

    # post final
    # in_file_cn = "/Users/tbachmann/Steffani/CN ME/04-post final/Steffani CN I-1_addrows.docx"
    in_file_cn = "../edition-74338566/resources/CN/ME CN final/CN_Steffani-ME_I-1_nospots.docx"

    # post-final
    # in_file_cn = '/Users/tbachmann/Steffani/CN ME/04-post final/Critical Notes_Akt-I_Anteil-MGi_Red_CS_Korr_MGi_2019-XI-05_red_SB_2022-IX-14-final_korrSB.docx'

    # out-file
    # out_file_cn = "../edition-74338566/resources/CN/ME CN final/Critical Notes_Akt-I_Anteil-MGi_Red_CS_Korr_MGi_2019-XI-05_red_SB_2022-IX-14-final_addcols_links_spotcleanup_numbers-annotid.docx"
    # out_file_cn = "../edition-74338566/resources/CN/ME CN final/2022-11-01_Critical Notes_Akt-I_Anteil-MGi_Red_CS_Korr_MGi_2019-XI-05_red_SB_2022-IX-14-final_addcols_links_spotcleanup_numbers-annotid_spots.docx"

    # post final
    # out_file_cn = "/Users/tbachmann/Steffani/CN ME/04-post final/Steffani CN I-1_addrows_annotids-splittitle.docx"
    out_file_cn = "../edition-74338566/resources/CN/ME CN final/CN_Steffani-ME_I-1.docx"

    # post-final
    # out_file_cn = '/Users/tbachmann/Steffani/CN ME/04-post final/Critical Notes_Akt-I_Anteil-MGi_Red_CS_Korr_MGi_2019-XI-05_red_SB_2022-IX-14-final_korrSB_cn-no.docx'

    # spots file
    in_file_spots = "../edition-74338566/resources/CN/ME CN final//Steffani ME CN Spots - Akt I-I (MGi).csv"

    # I-I: 1-108
    spot_id = 1
    # I-I: 1-346 (beware offset)
    cn_id = 0



  elif act == 'I-II':
    # in_file_cn = "../edition-74338566/resources/CN/ME CN final/Critical Notes_Akt-I_Anteil-CS_2022-III-17_korrAH_2022-VIII-30_finalCS_2022-VIII-31_numbers_links_addcols_annotid_spotscleanup.docx"
    # post final
    # in_file_cn = "../edition-74338566/resources/CN/ME CN final/CN_Steffani-ME_I-2_todo.docx"
    in_file_cn = "../edition-74338566/resources/CN/ME CN final/CN_Steffani-ME_I-2_nospots.docx"

    # post final
    # in_file_cn = '/Users/tbachmann/Steffani/CN ME/04-post final/Critical Notes_Akt-I_Anteil-CS_2022-III-17_korrAH_2022-VIII-30_finalCS_2022-VIII-31.docx'

    # out file
    # out_file_cn = "../edition-74338566/resources/CN/ME CN final/Critical Notes_Akt-I_Anteil-CS_2022-III-17_korrAH_2022-VIII-30_finalCS_2022-VIII-31_numbers_links_addcols_annotid_spotscleanup_spots-newtry.docx"
    # out_file_cn = "../edition-74338566/resources/CN/ME CN final/CN_Steffani-ME_I-2_nospots.docx"
    out_file_cn = "../edition-74338566/resources/CN/ME CN final/CN_Steffani-ME_I-2.docx"

    # post final
    # out_file_cn = '/Users/tbachmann/Steffani/CN ME/04-post final/Critical Notes_Akt-I_Anteil-CS_2022-III-17_korrAH_2022-VIII-30_finalCS_2022-VIII-31_cn-no.docx'

    # spots file
    in_file_spots = "../edition-74338566/resources/CN/ME CN final//Steffani ME CN Spots - Akt I-II (CS).csv"

    # I-II: 109-289
    # spot_id = 109
    spot_id = 200
    # I-II: 347-741
    cn_id = 346


  elif act == 'II':
    # in_file_cn = "../edition-74338566/resources/CN/ME CN final/Critical Notes_Akt-II_CS_end_2022-IV-22_korrAH_korrCS_numbers_links_addcols_annotid.docx"

    # post final
    in_file_cn = "../edition-74338566/resources/CN/ME CN final/CN_Steffani-ME_II_nospots.docx"

    # post-final
    # in_file_cn = '/Users/tbachmann/Steffani/CN ME/04-post final/Critical Notes_Akt-II_CS_end_2022-IV-22_korrAH_korrCS.docx'

    # out file
    # out_file_cn = "../edition-74338566/resources/CN/ME CN final/Critical Notes_Akt-II_CS_end_2022-IV-22_korrAH_korrCS_numbers_links_addcols_annotid_spots.docx"
    out_file_cn = "../edition-74338566/resources/CN/ME CN final/CN_Steffani-ME_II.docx"


    # post-final
    # out_file_cn = '/Users/tbachmann/Steffani/CN ME/04-post final/Critical Notes_Akt-II_CS_end_2022-IV-22_korrAH_korrCS_cn-no.docx'

    # spots file
    in_file_spots = "../edition-74338566/resources/CN/ME CN final//Steffani ME CN Spots - Akt II.csv"


    # II: 290-491
    # spot_id = 290
    spot_id = 500
    # II: 742-1245
    cn_id = 741


  elif act == 'III':
    # in_file_cn = "../edition-74338566/resources/CN/ME CN final/2022-11-03_Critical Notes_Akt-III_MGI_end_2019-XI-07_red_SB_2022-IX-30-final_addcols_links_no-splitno-annotid.docx"
    # post final
    in_file_cn = "../edition-74338566/resources/CN/ME CN final/CN_Steffani-ME_III_nospots.docx"

    # post-final
    # in_file_cn = '/Users/tbachmann/Steffani/CN ME/04-post final/Critical Notes_Akt-III_MGI_end_2019-XI-07_red_SB_2022-IX-29_korrSB.docx'

    # out file
    # out_file_cn = "../edition-74338566/resources/CN/ME CN final/2022-11-03_Critical Notes_Akt-III_MGI_end_2019-XI-07_red_SB_2022-IX-30-final_addcols_links_no-splitno-annotid_spots.docx"
    out_file_cn = "../edition-74338566/resources/CN/ME CN final/CN_Steffani-ME_III.docx"

    # post-final
    # out_file_cn = '/Users/tbachmann/Steffani/CN ME/04-post final/Critical Notes_Akt-III_MGI_end_2019-XI-07_red_SB_2022-IX-29_korrSB_cn-no.docx'

    # spots file
    in_file_spots = "../edition-74338566/resources/CN/ME CN final//Steffani ME CN Spots - Akt III.csv"

      # III: 492-751
    # spot_id = 492
    spot_id = 800
    # III: 1246-1883
    cn_id = 1245



  #in_file_cn = "Critical Notes_Akt-II_CS_end_2022-IV-22.docx"
  # output file
  #out_file_cn = "../../../edition-74338566/resources/CN/Critical_Notes_Akt-I_Anteil-CS_out.docx"
  # out_file_cn = "../edition-74338566/resources/CN/Critical Notes_Akt-II_CS_end_2022-IV-22_numbers_addcols_annotids.docx"
  # out_file_cn = "../edition-74338566/resources/CN/ME CN final/Critical Notes_Akt-I_Anteil-CS_2022-III-17_korrAH_2022-VIII-30_finalCS_2022-VIII-31_numbers_links_addcols_annotid.docx"

  # prefix of the annotation ids
  id_prefix = "opera_annot_"
  # id of annot id col (zero based index)
  annot_col_id = 1


  """ DEPR: spots_input:
  0: CN #
  1: Act
  2: Sc.
  3: No.
  4: spots (<siglum>, <surface-id>, <spot-id>, <top>, <left>, <breite>, <höhe>;)
  5...: not used notes
  """
  """ spots_input:
  0: CN #
  1: Act
  2: Sc.
  3: No.
  4: DEPR spots (<siglum>, <surface-id>, <spot-id>, <top>, <left>, <breite>, <höhe>;)
  5...: not used notes
  """



  spots_input = []
  spots = []

  # read spot csv file
  print(f'reading spot file: {in_file_spots}...')
  with open(in_file_spots, mode ='r') as file:
    csvFile = csv.reader(file)
    
    # read lines and remove unused data
    for line in csvFile:
      # break
      if line[0] == 'CN-No': continue
      # print(line)
      # spots_input.append(line[:5])
      spots_input.append(line)

      


  # for i, x in enumerate(spots_input):
  #   print(i, x)


  # XML-Stuff to find surface IDs
  # parse source files
  print('parsing sourcefiles...')
  # 66-A
  file_A    = minidom.parse('../edition-74338566/sources/opera_source_a8ee1f84-fc0f-4d21-a56f-72e4f93f91c4.xml')
  # 66-B
  file_B    = minidom.parse('../edition-74338566/sources/edirom_source_947bf706-3c36-41fd-9f09-5b995d067a74.xml')
  # 66-T-ME
  file_T_ME = minidom.parse('../edition-74338566/sources/opera_source_987507b4-a1ac-4de4-a9bb-173ea86d8449.xml')
  # 66-ME
  file_ME   = minidom.parse('../edition-74338566/sources/opera_edition_034306b9-b622-4a69-b072-b06e4bb86dd9.xml')

  # get surfaces of sources
  surfaces_A    = file_A   .getElementsByTagName('surface')
  surfaces_B    = file_B   .getElementsByTagName('surface')
  surfaces_T_ME = file_T_ME.getElementsByTagName('surface')
  surfaces_ME   = file_ME  .getElementsByTagName('surface')

  def get_surface_xmlid_by_n(source, n):
      if source == 'A':
          surfaces = surfaces_A
      elif source == 'B':
          surfaces = surfaces_B
      elif source == 'T':
          surfaces = surfaces_T_ME
      elif source == 'ME':
          surfaces = surfaces_ME
      else:
        print('ERROR: invalid source siglum')

      for surface in surfaces:
          surface_xmlid = surface.attributes['xml:id'].value
          surface_n = int(surface.attributes['n'].value)
          if surface_n == n:
              # print('surface_n:', surface_n)
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

  print("recalculating spots...")
  for spots in spots_input:
    # if spots[4] == '' or spots[0] == '': continue
    if spots[0] == '': continue
    # if spots[0] != '1211': continue
    # print('   ', spots)
    # for s in spots:
    #   print('   ', s)
    

    # # remove spaces and trailing ';' and split
    # spot = spots[4].replace(" ", "")
    # # print ('spot:', spot)
    # if spot[-1] == ';': spot = spot[:-1]
    # spot = spot.split(';')
    spot = []
    for i in range(6, 10):
      this_spot = spots[i].replace(" ", "")
      # print('this_spot:', this_spot)
      if len(this_spot) < 10: continue
      if this_spot[-1] == ';': this_spot = this_spot[:-1]

      # split if necessary
      if ';' in this_spot:
        for split_spot in this_spot.split(';'):
          spot.append(split_spot)
      else:
        spot.append(this_spot)
      # spot.append(spots[i].replace(" ", "").split(';'))
    # print('spot:', spot)

    
    # calculate coordinates
    spots_to_delete = []
    for i, s in enumerate(spot):
      # print('s:', s)
      spot[i] = s.split(',')

      # some spots still have the placeholder for spot-no
      if len(spot[i]) == 7:
        # print('too long...')
        del spot[i][2]

      # if one coordinate is missing, remove that spot
      if len(spot[i]) == 5:
        # spot[i] == ''
        # print('too short...', spot[i])
        # del spot[i]
        spots_to_delete.append(i)
        continue

      # print('spot[i]:', spot[i])

      # add spot id
      # spot[i][2] = f'{spot_id:04d}'
      spot[i].insert(2, f'{spot_id:04d}')
      spot_id += 1

      ulx = spot[i][4]
      uly = spot[i][3]
      lrx = str(int(spot[i][4]) + int(spot[i][5]))
      lry = str(int(spot[i][3]) + int(spot[i][6]))

      spot[i][3] = ulx
      spot[i][4] = uly
      spot[i][5] = lrx
      spot[i][6] = lry

      # find surface id
      # print(spot[i][0])
      spot[i][1] = get_surface_xmlid_by_n(spot[i][0], int(spot[i][1]))
      # print(spot[i][1])

      spot[i] = ','.join(spot[i])
      # print(spot[i])

    for i in spots_to_delete:
      del spot[i]

    spots[4] = ';'.join(spot)
    # print(spots[4])
    # print(spot)


    # break

  # print('')
  # print('')
  # for cn in spots_input:
  #   print(cn)
  # # print(spots_input[0])

  # exit()

  # open document
  print(f'open file: {in_file_cn}')
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
  actual_spot_id = 0
  last_no = ''
  last_name = ''
  print("iterating CN and adding annot_id, spots and split No. ...")
  for i, row in enumerate(doc.tables[0].rows):
    # first row is header
    if i < 1: continue
    # if i < 145: continue
    # if i == 6: break

    

    # CN No.
    cn_no = cn_id + i
    # row.cells[0].paragraphs[0].text = str(cn_no)

    # non_continue = [2, 3, 49, 235, 237, 734]
    # if cn_no not in non_continue:
    #   continue

    print(cn_no)
    
    # create new annot id
    # annot_id = id_prefix + str(uuid.uuid4())
    # row.cells[annot_col_id].paragraphs[0].text = annot_id

    # spots
    try:
        actual_spot = spots_input[actual_spot_id]
    except:
        # TODO: after last spot error will be thrown...
        actual_spot = [-1]
        # print(f'WARNING: could not find spot actual_spot_id: {actual_spot_id}')
        pass
    # print(actual_spot)
    if int(actual_spot[0]) == cn_no:
      # NOTE: check id
      print(actual_spot)
      row.cells[12].paragraphs[0].text = actual_spot[4]
      # print('actual_spot[4]:', actual_spot[4])
      actual_spot_id += 1
    


    """
    Die CNs für die Kategorie „S“ folgen also einem klaren Schema, das im Fall eines Rezitatives so aussieht:
    "Aktnummer als römische Zahl, Szenennummer als arabische Ziffer, Recitativo, Taktangabe (Lineangabe), ggf. Rollenbezeichnung"

    CN 2:
    first line: before line 1
    -> Sinfonia, (before line 1)
    -> (before line 1)

    CN 3:
    first line: before line 1
    -> XXXSinfonia, before bar 1 (before line 1)
    -> Sinfonia, (before line 1)
    -> (before line 1)

    CN 49:
    first bar: before bar 1
    first line: before line 4
    -> I,1 Recitativo, before bar 1 (after line 4)
    -> before bar 1 (after line 4)

    CN 235:
    ...
    -> I,6 Recitativo, bars 4-7 (lines 142-143), MET.
    -> bars 4-7 (lines 142-143), MET.

    CN 237:

    CN 734:
    -> No. 23, after bar 12 (after line 444), Hen.
    -> after bar 12 (after line 444), Hen.

    """

    # fix the shit with S annotations...
    category   = row.cells[15].paragraphs[0].text.strip()
    spot_title = row.cells[11].paragraphs[0].text.strip()
    additional_shit = [1725]
    if ('S' in category and 'Intro' not in spot_title) or cn_no in additional_shit:
      print(category, ':here we go!')

      act        = row.cells[2].paragraphs[0].text.strip()
      scene      = row.cells[3].paragraphs[0].text.strip()
      no         = row.cells[4].paragraphs[0].text.strip()
      full_name  = row.cells[5].paragraphs[0].text.strip()
      first_bar  = row.cells[6].paragraphs[0].text.strip()
      last_bar   = row.cells[7].paragraphs[0].text.strip()
      first_line = row.cells[8].paragraphs[0].text.strip()
      last_line  = row.cells[9].paragraphs[0].text.strip()
      system     = row.cells[10].paragraphs[0].text.strip()
      spot_title = ''

      # if no == "Sinfonia":
      #   spot_title += no
      # else:
      #   spot_title += act + "," + scene + " " + no 
      #   if full_name != "":
      #     spot_title += " " + full_name

      if first_bar != "":
        if 'before' in first_bar or 'after' in first_bar or 'beside' in first_bar:
          spot_title += first_bar
        else:
          if last_bar != "":
            spot_title += "bars " + first_bar + "-" + last_bar
          else:
            spot_title += "bar " + first_bar

        # TODO: last_bar
      
      if first_line != "":
        if first_bar != "":
          spot_title += " "
        if 'before' in first_line or 'after' in first_line or 'beside' in first_line:
          spot_title += "(" + first_line + ")"
        else:
          if last_line != "":
            spot_title += "(lines " + first_line + "-" + last_line + ")"
          else:
            spot_title += "(line " + first_line + ")"
        
      # clear bar & line cells
      row.cells[6].paragraphs[0].text = ""
      row.cells[7].paragraphs[0].text = ""
      row.cells[8].paragraphs[0].text = ""
      row.cells[9].paragraphs[0].text = ""

      if system != "" and system != "Spot":
        spot_title += ", " + system

      print('spot_title:', spot_title)

      # add spot title to docx
      row.cells[11].paragraphs[0].text = spot_title

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
    print(f'write output file: {out_file_cn}')
    doc.save(out_file_cn)

print('done:', ' '.join([act for act in acts]))
