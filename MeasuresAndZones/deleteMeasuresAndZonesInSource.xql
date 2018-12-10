xquery version "3.0";
(:   
    created: 5.6.2018, nbeer (OPERA)

:)

declare default element namespace "http://www.music-encoding.org/ns/mei";

declare namespace functx="http://www.functx.com";

declare option saxon:output "method=xml";
declare option saxon:output "media-type=text/xml";
declare option saxon:output "omit-xml-declaration=yes";
declare option saxon:output "indent=no";


let $contentsBasePath := '/Users/niko/Repos/OPERA-Edition/edition-74338557/'
let $sourceDocPath := 'sources/opera_edition_730ca1ed-05fb-4642-8159-d41aa1ec810e.xml'
let $sourceDocURI := concat($contentsBasePath, $sourceDocPath)
let $doc := doc($sourceDocURI)
let $surfaces := $doc//surface

for $surface at $pos in $surfaces[@n > 30]
    let $zones := $surface//zone
    return
        
        for $zone in $zones
            let $zoneID := $zone/@xml:id
            return
                
                (
                delete node $doc//measure[substring-after(@facs, '#') = $zoneID],
                delete node $zone
                )