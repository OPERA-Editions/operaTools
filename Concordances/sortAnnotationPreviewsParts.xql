xquery version "3.0";

declare default element namespace "http://www.music-encoding.org/ns/mei";

declare option saxon:output "method=xml";
declare option saxon:output "media-type=text/xml";
declare option saxon:output "omit-xml-declaration=yes";
declare option saxon:output "indent=no";

let $editionID := 'edition-74338557'
let $workID := 'opera_work_4fb7f9fb-12b0-4266-8da3-3c4420c2a714'
(:let $sourceID := 'opera_edition_730ca1ed-05fb-4642-8159-d41aa1ec810e':)

let $contentsBasePath := concat('../../', $editionID, '/')
let $sourcesColletction := collection(concat($contentsBasePath, 'sources/?select=*.xml;recurse=yes'))
let $workDoc := doc(concat($contentsBasePath, 'works/', $workID, '.xml'))
let $annotations := $workDoc//annot[@type = 'editorialComment']

for $annotation in $annotations
    let $plistT := tokenize(normalize-space($annotation/@plist), ' ')
    return
    
        for $p in $plistT
            let $sourceSig
            
    

return
$annotations