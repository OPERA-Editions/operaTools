xquery version "3.0";

(: 2018-06-06, taken from Reger-Werkausgabe Project Tool Set for usage
        in the OPERA Project, to be used in oXygen with Saxon EE.

        2018-06-06: modified to fit OPERA needs, nbeer, OPERA
        
        :)
        
declare default element namespace "http://www.music-encoding.org/ns/mei";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare option saxon:output "method=xml";
declare option saxon:output "media-type=text/xml";
declare option saxon:output "omit-xml-declaration=yes";
declare option saxon:output "indent=no";

let $editionID := 'edition-74338558'
let $workID := 'opera_work_d471efd4-7c6f-4e07-9195-8a6fd713f227'

let $contentsBasePath := concat('../../../', $editionID, '/')
let $sourcesDocs := collection(concat($contentsBasePath, 'sources/?select=*.xml'))

for $source in $sourcesDocs
let $sourceDoc := doc(document-uri($source))
let $spotZones := $sourceDoc//zone[@type = 'operaAnnotSpot']
return
    delete nodes $spotZones
