#!/bin/bash

# identifies file names and images dimensions
# from a given input directory and outputs a
# csv file to 'Desktop'.

# Needs ImageMagick to be installed!

# Nikolaos Beer, Max-Reger-Institut, Karlsruhe, 2017.
# Nikolaos Beer, modified for the OPERA Projekt, Frankfurt, July 2018

#####################################
# path to images:					#
#####################################
inputPath=~/Desktop/Bilder_neu_gesammelt

#####################################
# DO NOT CHANGE FROM HERE!			#
#####################################

outputFile=~/Desktop/dimensions.csv

rm $outputFile
cd $inputPath
touch $outputFile

find . -type f -iname \*.jpg | while read -r file
do
    identify -ping -format "$file;%wx%h\n" $file >> $outputFile
done
