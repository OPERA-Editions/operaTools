"""
This script adds preceding zero(s) to page numbers in image files.

You have to adjust the filenames in add_preceding_zeros() to your specifications.

Created on 2020-05-28
Author: tbachmann for OPERA
"""
from os import listdir, path, makedirs
from os.path import isfile, join
from shutil import copyfile, move

# path with original files
input_path = '/Users/tbachmann/Adam - Giselle/F-Pn Ms. 2644 (Source A) colour/Neu_Benannt_Sortiert'

# how long?
page_number_length = 3

# change names inplace
# True: change names of files (TODO)
# False: create new directory (output_path) with copies
change_inplace = False

# path where reduces files shoud be saved
output_path = input_path + '/_preceding-zeros'



def add_preceding_zeros(filename, page_number_length):
    """
    This function generates the new filename.
    You have to adjust it to your filenames.
    """
    if 'Cover' in filename:
        print('TODO: Cover')
        result = filename
    else:
        f = filename.rsplit('_', 1)
        prefix = f[0]
        postfix = f[1][-4:]
        page = f[1][:-5]
        folio = f[1][-5:-4]
        #print(f, prefix, page, folio, postfix)
        while len(page) < page_number_length:
            page = '0' + page

        result = "{}_{}{}{}".format(prefix, page, folio, postfix)
    return result

# dont change below

images = sorted([f for f in listdir(input_path) if isfile(join(input_path, f)) and f[-4:] == '.jpg'])

if change_inplace:
    print('renaming files...')
else:
    # create output dir if not existing
    if not path.exists(output_path):
        print('creating dir: {}'.format(output_path))
        makedirs(output_path)
        pass
    print('copying files with new names...')

for f in images:
    new_filename = add_preceding_zeros(f, page_number_length)
    src = input_path + '/' + f

    if change_inplace:
        print('renaming "{}" to "{}"'.format(f, new_filename))
        dst = input_path + '/' + new_filename

        move(src, dst)
    else:
        print('new file: "{}/{}"'.format(output_path, new_filename))
        dst = output_path + '/' + new_filename

        copyfile(src, dst)

print('done')