
'''
let $editionContentsBasePathString := '../../'
let $editionID := 'edition-74338567'
let $editionsContentsBasePath := concat($editionContentsBasePathString, $editionID, '/')
let $sourceID := 'opera_source_af56ff93-664f-4df2-817c-5ad6d826e850'

let $sourceDoc := doc(concat($editionsContentsBasePath, 'sources/', $sourceID, '.xml'))

let $siglum := 'A'

let $labelList := functx:lines(unparsed-text(concat($editionsContentsBasePath, 'resources/', $siglum, '/', $siglum, '-sequenceOfPages.csv')))

'''

editionContentsBasePathString = '../../../'
editionID = 'edition-74338567'
editionsContentsBasePath = editionContentsBasePathString + editionID + '/'
# sourceID = 'opera_source_af56ff93-664f-4df2-817c-5ad6d826e850'
# sourceDocPath = editionsContentsBasePath + 'sources/' + sourceID + '.xml'

dimemsionsPrefix = 'A_F-Pn-Ms-2644_'

siglum = 'A'

dimensionsFilePath = editionsContentsBasePath + 'resources/' + siglum + '/' + siglum + '_dimensions.csv'

sequenceFilePath = editionsContentsBasePath + 'resources/' + siglum + '/' + siglum + '-sequenceOfPages.csv'

pageNumberLenght = 3

with open(dimensionsFilePath) as f:
    dimensionsCSV = f.readlines()

def add_preceding_zeros(number, length):
    """
    This function generates the new filename.
    You have to adjust it to your filenames.
    """

    while len(number) < length:
        number = '0' + number

    return number

def remove_preceding_zeros(number):
    while number[0] == '0' and len(number) > 1:
        number = number[1:]
    return number

sequence = []
for i, imageDimension in enumerate(dimensionsCSV):
    # print(imageDimension)
    imageName = imageDimension.split(';')[0][:-4]
    # print(imageName)
    n = add_preceding_zeros(str(i + 1), pageNumberLenght)
    label = remove_preceding_zeros(imageName[len(dimemsionsPrefix):])
    # print(result)
    sequence.append(n + ';' + label)

for x in sequence:
    print(x)

with open(sequenceFilePath, 'w') as f:
    for page in sequence:
        f.write(page + '\n')
