xquery version "3.0";

declare default element namespace "http://www.music-encoding.org/ns/mei";
declare namespace functx = "http://www.functx.com";


declare option saxon:output "method=xml";
declare option saxon:output "media-type=text/xml";
declare option saxon:output "omit-xml-declaration=yes";
declare option saxon:output "indent=no";
declare function functx:lines 
    ($arg as xs:string?) as xs:string* {
    tokenize($arg, '(\r\n?|\n\r?)')
    };

let $editionID := 'edition-74338558'
let $sourceID := 'edirom_source_786a4e99-aacd-459d-a40a-79c894e92497'

let $contentsBasePath := concat('../../', $editionID, '/')
let $sourceDoc := doc(concat($contentsBasePath, 'sources/', $sourceID, '.xml'))
let $folioDoc := functx:lines(unparsed-text(concat($contentsBasePath, 'Resources/Source_A-folio-Zaehlung.csv')))

for $surface in $sourceDoc//surface[not(@label)]
    let $n := $surface/@n/string()
    let $label := for $folio in $folioDoc
                    where substring-before($folio, ';') = $n
                    return
                        substring-after($folio, ';')
    return
        insert nodes attribute label {$label} into $surface
