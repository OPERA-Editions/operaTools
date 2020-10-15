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
let $sourceID := 'opera_source_987507b4-a1ac-4de4-a9bb-173ea86d8449'

let $sourceDoc := doc(concat($editionsContentsBasePath, 'sources/', $sourceID, '.xml'))

let $surfaces := $sourceDoc//surface

for $surface at $pos in $surfaces
    
    return
        replace value of node $surface/@n with $pos
