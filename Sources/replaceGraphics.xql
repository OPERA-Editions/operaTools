xquery version "3.0";

declare default element namespace "http://www.music-encoding.org/ns/mei";

declare namespace imglist = "http://opera.uni-frankfurt.de/imglist";
declare namespace opera = "http://opera.uni-frankfurt.de/opera";
declare namespace uuid = "java:java.util.UUID";
import module namespace functx = "http://www.functx.com" at "../Resources/functx.xq";


declare option saxon:output "method=xml";
declare option saxon:output "media-type=text/xml";
declare option saxon:output "omit-xml-declaration=yes";
declare option saxon:output "indent=yes";

let $editionContentsBasePathString := '../../'
let $editionID := ''
let $editionsContentsBasePath := concat($editionContentsBasePathString, $editionID, '/')
let $sourceID := ''

let $sourceDoc := doc(concat($editionsContentsBasePath, 'sources/', $sourceID, '.xml'))

let $siglum := 'T'

let $imageList := functx:lines(unparsed-text(concat($editionsContentsBasePath, 'resources/', $siglum, '_dimensions.csv')))
let $imagesFakeCount := count($imageList)

let $surfaces := $sourceDoc//surface

for $surface at $pos in $surfaces
    let $newDataFromImageList := tokenize($imageList[$pos], ';')
    let $newResourceName := $newDataFromImageList[1]
    let $newDimensionX := substring-before($newDataFromImageList[2], 'x')
    let $newDimensionY := substring-after($newDataFromImageList[2], 'x')
    let $oldGraphic := $surface/graphic
    let $newGraphic := element graphic {
                        attribute xml:id {concat('opera_graphic_', uuid:randomUUID())},
                        attribute target {concat($editionID, '/', $sourceID, '/', $newResourceName)},
                        attribute type {'facsimile'},
                        attribute width {$newDimensionX},
                        attribute height {$newDimensionY}
                        }
               return
               replace node $oldGraphic with $newGraphic