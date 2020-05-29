"""
This script changes the Quality of all JPGs in a directory to a given value.

Dependencies:
* Pillow (pip install pillow or conda install pillow)

TODO:
* include subfolders

Created on 2020-05-28
Author: tbachmann for OPERA
"""
# path with original files
input_path = '/Users/tbachmann/Adam - Giselle/F-Pn Ms. 2644 (Source A) colour/Neu_Benannt_Sortiert/_preceding-zeros'

# quality rate
quality_rate = 94

# path where reduces files shoud be saved
output_path = input_path + '/_' + str(quality_rate)


# dont change below

try:
    from PIL import Image
except:
    print("Needs Python-Package 'pillow', please install.")
    exit()

from os import listdir, path, makedirs
from os.path import isfile, join

images = sorted([f for f in listdir(input_path) if isfile(join(input_path, f)) and f[-4:] == '.jpg'])

# create output dir if not existing
if not path.exists(output_path):
    makedirs(output_path)

print('compressing files (rate: {})...'.format(quality_rate))

for f in images:
    # print(input_path + '/' + f + '...')
    im = Image.open(input_path + '/' + f)
    im.save(output_path + '/' + f, quality=quality_rate)
    print('new file: ' + output_path + '/' + f)
print('done')