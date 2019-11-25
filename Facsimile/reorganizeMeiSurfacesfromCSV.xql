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

let $editionID := 'edition-74338566'

let $sourceID := 'opera_source_a8ee1f84-fc0f-4d21-a56f-72e4f93f91c4'

let $contentsBasePath := concat('../../', $editionID, '/')
let $sourceDoc := doc(concat($contentsBasePath, 'sources/', $sourceID, '.xml'))
let $folioDoc := (functx:lines(unparsed-text(concat($contentsBasePath, 'resources/A/A-vol1-sequenceOfPages.csv'))), functx:lines(unparsed-text(concat($contentsBasePath, 'resources/A/A-vol2-sequenceOfPages.csv'))), functx:lines(unparsed-text(concat($contentsBasePath, 'resources/A/A-vol3-sequenceOfPages.csv'))))

for $surface in $sourceDoc//surface[not(@label)]
    let $n := $surface/@n/string()
    let $label := if (number($n) < 120)
                    then (concat('1 – ', substring-after($folioDoc[substring-before(., ';') = $n], ';')))
                    else if (number($n) > 119 and number($n) < 213)
                    then (concat('2 – ', substring-after($folioDoc[substring-before(., ';') = $n], ';')))
                    else if (number($n) > 212)
                    then (concat('3 – ', substring-after($folioDoc[substring-before(., ';') = $n], ';')))
                    else ()
    (:let $label := for $folio in $folioDoc
                    where substring-before($folio, ';') = $n
                    return
                        substring-after($folio, ';'):)
    return
    concat($n, ' = ', $label)
        (:insert nodes attribute label {$label} into $surface:)
