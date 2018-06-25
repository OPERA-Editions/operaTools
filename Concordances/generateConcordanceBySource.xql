xquery version "3.0";

(:~
: make edirom concordances
: single work
: define first: - sources form edition's source Collection?
                - sources form edirom edition file aka sources in navigator?
                - sources by MEI metadata
:)

declare default element namespace "http://www.edirom.de/ns/1.3";

declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace functx="http://www.functx.com" at "../Resources/functx.xq";

declare option saxon:output "method=xml";
declare option saxon:output "media-type=text/xml";
declare option saxon:output "omit-xml-declaration=yes";
declare option saxon:output "indent=yes";

(:  First, decide which type of concordance you wish to generate.
    You can choose between:
        - Generating concordance based on all source files
            found in the edirom edition's sources collection.
            Value: 'sourceCollection'
        - Generating concordance based on sources that are
            linkt in the navigator of the edirom edition.
            Value: 'ediromNavigatorSources'
        - Generating concordance based on MEI metadata.
            Value: 'meiRelation'
        - Generating concordance from list of sources.
            Value: 'sourcesList'
:)
let $ediConcType := 'sourceCollection'

(:  If value of $ediConcType is 'sourceList', please
    define your source list in the following array.
    ('source_a', 'source_b')
:)
let $sourcesList := ()

(:  ID of Edirom edition file. :)
let $editionID := 'edition-74338557'

(:  ID of MEI work file. :)
let $workID := 'opera_work_4fb7f9fb-12b0-4266-8da3-3c4420c2a714'

(:  ID(s) of reference source(s). Mostly the edition(s). :)
let $referenceSourceIDs := ('opera_source_medea_A1', 'TextEdition_Gotha')

(:  Base path string to the edition's contents :)
let $contentsBasePathString := '/Users/niko/Repos/OPERA-Edition/'


(:  DO NOT CHANGE FROM HERE!! :)

(:  Edition contents base path :)
let $contentsBasePath := concat($contentsBasePathString, $editionID, '/')

let $connectionPlistPrefix := concat('xmldb:exist:///db/contents/', $editionID, '/')

(:  Edirom edition doc :)
let $editionEdiromDoc:= doc(concat($contentsBasePath, $editionID, '.xml'))

(:  Work doc :)
let $workDoc := doc(concat($contentsBasePath, 'works/', $workID, '.xml'))

(:  Reference source docs :)
let $refSourcesDocs := for $referenceSourceID in $referenceSourceIDs
                        return
                            collection(concat($contentsBasePath, '?select=*.xml;recurse=yes'))[./*/@xml:id/string() = $referenceSourceID]

(: Sources to concord :)
let $ediConcSourcesCollection := if ($ediConcType = 'sourceCollection')
                                    then (
                                        let $sourcesMEI := collection(concat($contentsBasePath, 'sources/?select=*.xml'))[.//mei:mei]
                                        let $sourcesTEI := collection(concat($contentsBasePath, 'texts/?select=*.xml'))[starts-with(.//tei:TEI/@xml:id/string(), 'TextEdition')]
                                        return
                                            ($sourcesMEI, $sourcesTEI)
                                            
                                    )
                                    
                                    else if ($ediConcType = 'ediromNavigatorSources')
                                    then
                                        (
                                            for $target in $editionEdiromDoc//work[@xml:id = $workID]//navigatorItem[starts-with(@targets, $connectionPlistPrefix)]/@targets
                                            let $localURI := concat($contentsBasePath, substring-after($target/string(), concat($editionID, '/')))
                                            return
                                                $localURI
                                        )
                                    
                                    else if ($ediConcType = 'meiRelation')
                                    then () (: ToDo, with respect to TEI :)
                                    else if ($ediConcType = 'sourcesList')
                                    then () (: ToDo :)
                                    else()
                                    
(: OPERA-Spezialbehandlung :)

(:let $mdivsReference := $refSourceDoc//mei:mdiv:)

return
    element concordances {
        for $refSourceDoc in $refSourcesDocs
            let $concName :=    if (
                                    $refSourceDoc/tei:TEI
                                )
                                then (
                                    'Text Gotha 1775'
                                )
                                else if (
                                    $refSourceDoc/mei:mei
                                )
                                then (
                                    'Score 1784'
                                )
                                else (
                                    'empty'
                                )
            return
                element concordance {
                attribute name {$concName},
                    element groups {
                    attribute label {'Scene'},
                        let $divisions :=   if (
                                                $refSourceDoc/tei:TEI
                                            )
                                            then (
                                                $refSourceDoc//tei:div[@type = 'scene']
                                            )
                                            else if (
                                                $refSourceDoc/mei:mei
                                            )
                                            then (
                                                $refSourceDoc//mei:mdiv
                                            )
                                            else () 
                        for $div in $divisions
                        let $divName := if (
                                            $refSourceDoc/tei:TEI
                                        )
                                        then (
                                            $div/tei:head/text()
                                        )
                                        else if (
                                            $refSourceDoc/mei:mei
                                        )
                                        then (
                                            $div/@label
                                        )
                                        else ()
                        let $divSections :=   if (
                                                $refSourceDoc/tei:TEI
                                            )
                                            then (
                                                $div//tei:seg
                                            )
                                            else if (
                                                $refSourceDoc/mei:mei
                                            )
                                            then (
                                                $div//mei:measure
                                            )
                                            else ()
                        return
                            element group {
                            attribute name {$divName},
                                element connections {
                                attribute label {if ($refSourceDoc/tei:TEI)
                                                    then ('Text segment')
                                                    else if ($refSourceDoc/mei:mei)
                                                    then ('Bar/Text segment')
                                                    else ('empty')
                                                    },
                                    for $divSection in distinct-values($divSections/@n)
                                    return
                                        element connection {
                                        attribute name {$divSection},
                                        attribute plist {
                                            if (not(starts-with($divSection, 'seg')))
                                            then (
                                                let $ediConcSourcesCollectionFiltered := $ediConcSourcesCollection[not(matches(./*/@xml:id/string(), 'TextEdition'))][not(matches(./*/@xml:id/string(), 'opera_source_medea_T'))]
                                                for $ediConcSource in $ediConcSourcesCollectionFiltered
                                                let $sourceID := $ediConcSource/*/@xml:id/string()
                                                let $participant := if ($refSourceDoc/tei:TEI)
                                                                    then ()
                                                                    else if ($refSourceDoc/mei:mei)
                                                                    then (
                                                                        if (
                                                                            $ediConcSource//mei:parts
                                                                        )
                                                                        then (
                                                                            concat($connectionPlistPrefix, 'sources/', $sourceID, '.xml#', 'measure_', $ediConcSource//mei:mdiv[@label = $divName]/@xml:id/string(), '_', $divSection)
                                                                        )
                                                                        else (
                                                                            let $sourceMeasures2Conc := $ediConcSource//mei:measure[@n = $divSection and .//ancestor::mei:mdiv[@label = $divName]]
                                                                            let $sourceMeasures2ConcCount := count($sourceMeasures2Conc)
                                                                            return
                                                                                if (
                                                                                    $sourceMeasures2ConcCount > 1
                                                                                )
                                                                                then (
                                                                                    concat($connectionPlistPrefix, 'sources/', $sourceID, '.xml#', $sourceMeasures2Conc[1]/@xml:id/string(), '.xml?tstamp2=', $sourceMeasures2ConcCount - 1, 'm+0')
                                                                                )
                                                                                else (
                                                                                    concat($connectionPlistPrefix, 'sources/', $sourceID, '.xml#', $sourceMeasures2Conc[1]/@xml:id/string())
                                                                                )
                                                                        )
                                                                    )
                                                                    else ()
                                                
                                                return
                                                    $participant
                                            )
                                            else if (starts-with($divSection, 'seg'))
                                            then (
                                                for $ediConcSource in $ediConcSourcesCollection
                                                let $sourceID := $ediConcSource/*/@xml:id/string()
                                                let $participant := if ($refSourceDoc/tei:TEI)
                                                                    then ()
                                                                    else if ($refSourceDoc/mei:mei)
                                                                    then (
                                                                        if (
                                                                            $ediConcSource//mei:parts
                                                                        )
                                                                        then (
                                                                            concat($connectionPlistPrefix, 'sources/', $sourceID, '.xml#', 'measure_', $ediConcSource//mei:mdiv[@label = $divName]/@xml:id/string(), '_', $divSection)
                                                                        )
                                                                        else if ($ediConcSource/tei:TEI
                                                                        )
                                                                        then (
                                                                            let $sourceSegs2Conc := $ediConcSource//tei:seg[@n = substring-after($divSection, 'seg_') and .//ancestor::tei:div/tei:head[. = $divName]]
                                                                            
                                                                            return
(:                                                                            $sourceSegs2Conc:)
                                                                                concat($connectionPlistPrefix, 'texts/', $sourceID, '.xml#', $sourceSegs2Conc[1]/@xml:id/string())
                                                                        )
                                                                        else (
                                                                            let $sourceMeasures2Conc := $ediConcSource//mei:measure[
                                                                                (
                                                                                if (starts-with(./@n/string(), 'seg_') and matches(./@n/string(), '-'))
                                                                                then(number(substring-before(substring-after(./@n/string(), 'seg_'), '-')) <= number(substring-after($divSection, 'seg_')) and number(substring-after(substring-after(./@n/string(), 'seg_'), '-')) >= number(substring-after($divSection, 'seg_')))
                                                                                else if (starts-with(./@n/string(), 'seg_') and not(matches(./@n/string(), '-')))
                                                                                then (number(substring-after(./@n/string(), 'seg_')) = number(substring-after($divSection, 'seg_')))
                                                                                else ()
                                                                                )
                                                                                and
                                                                                (
                                                                                .//ancestor::mei:mdiv[@label = $divName]
                                                                                )
                                                                                ]
                                                                            let $sourceMeasures2ConcCount := count($sourceMeasures2Conc)
                                                                            return
                                                                                if (
                                                                                    $sourceMeasures2ConcCount > 1
                                                                                )
                                                                                then (
                                                                                    concat($connectionPlistPrefix, 'sources/', $sourceID, '.xml#', $sourceMeasures2Conc[1]/@xml:id/string(), '.xml?tstamp2=', $sourceMeasures2ConcCount - 1, 'm+0')
                                                                                )
                                                                                else (
                                                                                    concat($connectionPlistPrefix, 'sources/', $sourceID, '.xml#', $sourceMeasures2Conc[1]/@xml:id/string())
                                                                                )
                                                                        )
                                                                    )
                                                                    else()
                                                
                                                return
                                                    $participant
                                            )
                                            else ()
                                            
                                        }
                                    
                                    }
                                }
                            }
                    }
                }
                
    }