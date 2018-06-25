xquery version "3.0";

declare default element namespace "http://www.music-encoding.org/ns/mei";

declare option saxon:output "method=xml";
declare option saxon:output "media-type=text/xml";
declare option saxon:output "omit-xml-declaration=yes";
declare option saxon:output "indent=no";

let $editionID := 'edition-74338557'
let $sourceID := 'opera_edition_730ca1ed-05fb-4642-8159-d41aa1ec810e'

let $contentsBasePath := concat('../../', $editionID, '/')
let $sourceDoc := doc(concat($contentsBasePath, 'sources/', $sourceID, '.xml'))

for $measure in $sourceDoc//measure[not(@label)]
    let $label := if (contains($measure/@n/string(), 'seg_'))
                    then (concat('seg ', substring-after($measure/@n/string(), 'seg_')))
                    else ($measure/@n/string())
    return
        insert node attribute label {$label} into $measure