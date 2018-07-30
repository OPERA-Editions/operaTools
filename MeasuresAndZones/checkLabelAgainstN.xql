xquery version "3.0";

declare default element namespace "http://www.music-encoding.org/ns/mei";

declare option saxon:output "method=xml";
declare option saxon:output "media-type=text/xml";
declare option saxon:output "omit-xml-declaration=yes";
declare option saxon:output "indent=yes";


<root>

{

let $editionID := 'edition-74338557'
let $sourceID := 'opera_source_medea_A2'

let $contentsBasePath := concat('../../', $editionID, '/')
let $sourceDoc := doc(concat($contentsBasePath, 'sources/', $sourceID, '.xml'))



for $measure in $sourceDoc//measure
    let $measureID := $measure/@xml:id
    let $measureN := $measure/@n
    let $label := $measure/@label
    
    return
        <measure xml:id="{$measureID}" n="{$measureN}" label="{$label}"/>
        
}
</root>