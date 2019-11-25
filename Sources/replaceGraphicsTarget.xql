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
declare option saxon:output "saxon:indent-spaces=4";

let $editionContentsBasePathString := '../../'
let $editionID := 'edition-74338558'
let $editionsContentsBasePath := concat($editionContentsBasePathString, $editionID, '/')
let $sourceID := 'opera_edition_3578ef42-491f-4bc1-a426-728553f3cdba'

let $sourceDoc := doc(concat($editionsContentsBasePath, 'sources/', $sourceID, '.xml'))

let $graphics := $sourceDoc//graphic

for $graphic at $pos in $graphics

    let $newTarget := concat(functx:substring-before-last($graphic/@target/string(), '_'), '_s', format-number($pos + 6, '000'))
    
    
   return
    replace value of node $graphic/@target with $newTarget
(:$newTarget:)