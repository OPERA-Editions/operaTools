xquery version "3.0";

declare default element namespace "http://www.music-encoding.org/ns/mei";

declare namespace imglist = "http://opera.uni-frankfurt.de/imglist";
declare namespace opera = "http://opera.uni-frankfurt.de/opera";
import module namespace functx = "http://www.functx.com" at "../Resources/functx.xq";

declare option saxon:output "method=xml";
declare option saxon:output "media-type=text/xml";
declare option saxon:output "omit-xml-declaration=yes";
declare option saxon:output "indent=yes";
declare option saxon:output "saxon:indent-spaces=4";

let $editionContentsBasePathString := '../../'
let $editionID := 'edition-74338566'
let $editionsContentsBasePath := concat($editionContentsBasePathString, $editionID, '/')
let $sourceID := 'edirom_source_947bf706-3c36-41fd-9f09-5b995d067a74'

let $sourceDoc := doc(concat($editionsContentsBasePath, 'sources/', $sourceID, '.xml'))

let $siglum := 'B'

let $labelList := functx:lines(unparsed-text(concat($editionsContentsBasePath, 'resources/', $siglum, '/', $siglum, '-sequenceOfPages.csv')))

let $surfaces := $sourceDoc//surface

for $surface at $pos in $surfaces
    
    let $label := tokenize($labelList[$pos], ';')[2]
    
    return
(:        concat($pos, ' | ', $label):)
        insert node (attribute label {$label}) into $surface
