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

let $annotations := doc(concat($contentsBasePath, 'resources/CR_Medea_Music.xml'))//tei:table[@xml:id='Table1']/tei:row[position() > 1 ]

for $annotation at $pos in $annotations
    let $spotsT := tokenize(normalize-space($annotation//tei:cell[10]), '; ')
(:    where $pos = 1:)
    return
        for $spot in $spotsT
            let $spotT := tokenize($spot, ', ')
            (: just for info: :)
            let $sourceSiglum := $spotT[1]
            (: we later search the right source by surfaceID… :)
            let $spotSurfaceID := $spotT[2]
            let $spotID := $spotT[3]
            let $spotULX := $spotT[4]
            let $spotULY := $spotT[5]
            let $spotLRX := $spotT[6]
            let $spotLRY := $spotT[7]
            (: des isch jetzt e' biss'l komisch: erst die URI finden, dann nochmal das Dokument einlesen. Geht das nicht einfacher, denn eigentlich haben wir das ja schon??!! :)
            let $spotSurfaceSourceDocURI := document-uri(root($sourcesDocs/id($spotSurfaceID)))
            let $spotSurface := doc($spotSurfaceSourceDocURI)//surface[@xml:id = $spotSurfaceID]
            
            let $spotZone := <zone xml:id="{concat('opera_zone_', $editionID, '_', $spotID)}" type="operaAnnotSpot" ulx="{$spotULX}" uly="{$spotULY}" lrx="{$spotLRX}" lry="{$spotLRY}"/>
            
            return
                insert node $spotZone as last into $spotSurface
