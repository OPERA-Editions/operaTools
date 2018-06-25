xquery version "3.0";

(: 2018-06-06, taken from Reger-Werkausgabe Project Tool Set for useage
        in the OPERA Project, to be used in oXygen with Saxon EE.

        2018-06-06: modified to fit OPERA needs, nbeer, OPERA
        
        :)
        
declare default element namespace "http://www.music-encoding.org/ns/mei";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare option saxon:output "method=xml";
declare option saxon:output "media-type=text/xml";
declare option saxon:output "omit-xml-declaration=yes";
declare option saxon:output "indent=no";

let $editionID := 'edition-74338557'
let $workID := 'opera_work_4fb7f9fb-12b0-4266-8da3-3c4420c2a714'

let $contentsBasePath := concat('../../../', $editionID, '/')
let $sourcesDocs := collection(concat($contentsBasePath, 'sources/?select=*.xml'))

for $source in $sourcesDocs
let $spotZones := $source//zone[@type = 'operaAnnotSpot']
return
    delete nodes $spotZones
