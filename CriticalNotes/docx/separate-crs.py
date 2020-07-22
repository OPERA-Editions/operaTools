'''
This script checks if an annot_id is used more than once.
Hacky mess, but it works...

TODO:
- cleanup

Required pythonmodules:
- python-docx
- python-copy
- python-uuid

Created on 2019-12-10
Author: tbachmann
'''
import docx
import copy
import uuid
import json

# input file
inFile = '../../../edition-74338558/Resources/CN/CN_LiaV.docx'
inFile = '/Users/tbachmann/tmp/liav-cn/CN_LiaV_pre_split.docx'
# output file
outFile = 'CN_LiaV-crs.docx'
# input file with ids
inFileIDs = 'separate-ids.txt'
# prefix of the annotation ids
idPrefix = "opera_annot_"

# read IDs
IDs = []
with open(inFileIDs, 'r') as f:
    for line in f:
        IDs.append(int(line))
print(IDs)

# open document
doc = docx.Document(inFile)
thisTable = doc.tables[0]
# [[numberToInsert, row]]
rowsToAppend = []

# go over all cells in the first table
for i, row in enumerate(thisTable.rows):
    # first row is header
    if i < 64:
        continue
    if i > 64:
        break
    print('i:', i)

    # firstBarsCell = row.cells[4].text
    # if len(firstBarsCell) == 0:
    #     thisFirstBars = []
    # else:
    #     thisFirstBars = list(map(int, row.cells[4].text.split(',')))

    # if len(thisFirstBars) < 2:
    #     continue
    # print('thisFirstBars: -', thisFirstBars,'-')

    thisAnnotID = row.cells[1].text
    # print(thisAnnotID)
    # print(row.cells[0].text)
    # thisLfdNr = int(row.cells[0].text.replace('.',''))
    # print('thisLfdNr:', thisLfdNr)

    # print('Lfd. No.', row.cells[0].text)
    # Lfd. No. -> cell id -> i

    # check if relevant
    if i not in IDs:
        continue

    # print(thisAnnotID)
    thisFirstBars = list(map(int, row.cells[4].text.split(',')))
    print('thisFirstBars:', thisFirstBars)

    # print('len(thisFirstBars):', len(thisFirstBars))
    # if cell has only one First bar: continue
    if len(thisFirstBars) < 2:
        continue


    thisRow = []
    for x in row.cells:
        thisRow.append(x.text)
    print('thisRow:', thisRow, '\n=====')

     # remove annot_id
    thisRow[1] = ''
    # remove first bars
    thisRow[4] = ''
    # print(dummy)

    thisAnnotIDs = {}
    for x in thisFirstBars:
        thisAnnotIDs[x] = ''
    thisAnnotIDs[thisFirstBars[0]] = thisAnnotID
    # print(thisAnnotIDs)



    # print(thisRow[14])

    thisNew = []
    for x in thisFirstBars[1:]:
        # print('x:', x)
        thisNew.append(copy.deepcopy(thisRow))
        thisNew[-1][4] = str(x)
        # create new annot_id
        thisUUID = idPrefix + str(uuid.uuid4())
        thisNew[-1][1] = thisUUID
        thisAnnotIDs[x] = thisUUID
        # TODO: create new annot_id
        # thisNew[-1][1].text = ''
    # print('thisNew:', thisNew)

    # print('thisNew:', '='*40)
    for x in thisNew:
        # print('x:', x)
        # update 'Note' col
        plural = 's' if len(thisFirstBars) > 2 else ''
        noteAppendix = '; see bar{}&#160;'.format(plural)

        for y in thisFirstBars:
            # print('x[4], y:', x[4], y)
            if y != int(x[4]):
                noteAppendix += '<ref target="xmldb:exist:///db/contents/edition-74338558/works/opera_work_d471efd4-7c6f-4e07-9195-8a6fd713f227.xml#{}">{}</ref>, '.format(thisAnnotIDs[y], y)
        noteAppendix = noteAppendix[:-2]
        print('noteAppendix:', noteAppendix)
        
        # add noteAppendix to new row
        x[14] += noteAppendix

    for x in thisNew:
        # print(x)
        rowsToAppend.append(x)


    # update base row
    baseRow = row.cells
    # remove other bars from [4]
    baseRow[4].text = str(thisFirstBars[0])
    # print(baseRow[4].text)

    # add refs to [14]
    plural = 's' if len(thisFirstBars) > 2 else ''
    noteAppendix = '; see bar{}&#160;'.format(plural)

    for y in thisFirstBars[1:]:
        # print('x[4], y:', x[4], y)
        noteAppendix += '<ref target="xmldb:exist:///db/contents/edition-74338558/works/opera_work_d471efd4-7c6f-4e07-9195-8a6fd713f227.xml#{}">{}</ref>, '.format(thisAnnotIDs[y], y)
    noteAppendix = noteAppendix[:-2]
    baseRow[14].text += noteAppendix
    # print(noteAppendix)

for x in rowsToAppend:
    print(x[:-8])

if False:
    print('caching table...')
    # speed it up:
    cacheTable = []
    for i, row in enumerate(thisTable.rows):
        # use the headerrow too, saves reindexing
        # if i > 20:
        #     break

        cacheTable.append([row.cells[3].text, row.cells[4].text])
        # print(row.cells[3].text, x[3])

    # cache relevant table content
    with open('table', 'w') as outfile:
        json.dump(cacheTable, outfile, indent=4)
else:
    print('loading table...')
    # load relevant table content
    with open('table') as json_file:
        cacheTable = json.load(json_file)

# for x in table:
#     print(x)

# add new lines to doc-table
for x in rowsToAppend[::-1]:
    print('='*50)
    print(x[:-7])
    inserted = False
    for i, row in enumerate(cacheTable):
        thisNo = row[0].strip()
        # print(thisNo, x[3])

        # wrong No: continue
        if thisNo != x[3]:
            continue
        # print(row[1])
        if len(row[1]) == 0:
            continue

        # if there are more than one First bar, take the first
        try:
            thisBar = int(x[4])
        except ValueError:
            thisBar = int(x[4].split(',')[0])

        # if there are more than one First bar, take the first
        try:
            thisRow = int(row[1])
        except ValueError:
            thisRow = int(row[1].split(',')[0])
            print('WARNING:', thisNo, thisBar, thisRow)

        # print('===', thisNo, '--', x[3], '--', thisBar, '--', row[1])
        # print(row[0], thisBar)

        if thisBar < thisRow:
            print('insert before:', i)
            # row_cells = thisTable.add_row().cells
            # for i, x in enumerate(x):
            #     # row_cells[i].text = x


            # https://stackoverflow.com/questions/46215464/possible-to-insert-row-at-specific-position-with-python-docx
            insertRow = thisTable.rows[i]._tr
            insertRow.addnext(copy.deepcopy(thisTable.rows[i]._tr))
            newRow = thisTable.rows[i]
            # newRow.cells[1].text = 'asfd'
            for j, cell in enumerate(newRow.cells[1:]):
                cell.text = x[j+1]
            print('Inserted {}, {} in table.'.format(newRow.cells[3].text, newRow.cells[4].text))

            # for row in doc.tables[0].rows[146:150]:
            #     print(row.cells[1].text)
            cacheTable.insert(i, [newRow.cells[3].text, newRow.cells[4].text])
            # tr = insertRow._tr # this is a CT_Row element
            # print(tr)
            # # tr.addnext(thisTable.rows[0])
            # tr.addnext(tr)
            # # for new_tr in build_rows(): # build_rows should return list/iterator of CT_Row instance
            # #     tr.addnext(new_tr)
            inserted = True


            break

    if not inserted:
        print('WARNING: no place found for "{}" First bar: "{}"!'.format(x[3], x[4]))



print('='*50, 'rowsToAppend:')
for x in rowsToAppend:
    print(x)
    # pass


# for x in cacheTable:
#     print(x)


# annot_id lfd.no. 64
# opera_annot_d1e08868-20e5-409f-843d-e9a78d9bfe87
# annot_id lfd.no.98
# opera_annot_30ae5c4f-9f37-4d51-ad34-7f4dacd23f74


# write file
# doc.save(outFile)