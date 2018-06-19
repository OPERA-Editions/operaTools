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

(:  ID of reference source. Mostly the edition. :)
let $referenceSourceID := 'opera_source_medea_A1'

(:  Base path string to the edition's contents :)
let $contentsBasePathString := '/Users/niko/Repos/OPERA-Edition/'


(:  DO NOT CHANGE FROM HERE!! :)

(:  Edition contents base path :)
let $contentsBasePath := concat($contentsBasePathString, $editionID, '/')

let $connectionPlistPrefix := concat('xmldb:exist:///db/contents/', $editionID, '/sources/')

(:  Edirom edition doc :)
let $editionEdiromDoc:= doc(concat($contentsBasePath, $editionID, '.xml'))

(:  Work doc :)
let $workDoc := doc(concat($contentsBasePath, 'works/', $workID, '.xml'))

(:  Reference source doc :)
let $refSourceDoc := doc(concat($contentsBasePath, 'sources/', $referenceSourceID, '.xml'))

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

let $mdivsReference := $refSourceDoc//mei:mdiv

return
(:$ediConcSourcesCollection:)

    element concordances {
        for $mdivReference at $pos in $mdivsReference
            let $concName := $mdivReference/@label/string()
            let $mdivReferenceMeasures := $mdivReference//mei:measure
            let $measures := $mdivReferenceMeasures[not(matches(@label, 'seg'))]
            let $segs := $mdivReferenceMeasures[matches(@label, 'seg')]
(:            where $pos = 2:)
            return
                element concordance {
                    attribute name {$concName},
                    if ($segs)
                    then (
                            element groups {
                                attribute label {"&#160;&#160;"},
                                element group {
                                    attribute name {"Navigation by bar"},
                                    element connections {
                                        attribute label {"Bar"},
                                            for $measureNo in distinct-values($measures/@label)
                                                return
                                                    element connection {
                                                        attribute name {$measureNo},
                                                        attribute plist {
                                                            for $ediConcSource in $ediConcSourcesCollection[.//mei:mei][not(matches(.//mei:mei/@xml:id/string(), 'opera_source_medea_T'))]
                                                                let $sourceID := $ediConcSource/mei:mei/@xml:id/string()
                                                                let $participant := if (
                                                                                        $ediConcSource//mei:parts
                                                                                    )
                                                                                    then (
                                                                                        concat($connectionPlistPrefix, $sourceID, '.xml#', 'measure_', $ediConcSource//mei:mdiv[@label = $concName]/@xml:id/string(), '_', $measureNo, ' ')
                                                                                    )
                                                                                    else (
                                                                                        let $sourceMeasures2Conc := $ediConcSource//mei:measure[@label = $measureNo and .//ancestor::mei:mdiv[@label = $concName]]
                                                                                        let $sourceMeasures2ConcCount := count($sourceMeasures2Conc)
                                                                                        return
                                                                                            if (
                                                                                                $sourceMeasures2ConcCount > 1
                                                                                            )
                                                                                            then (
                                                                                                concat($connectionPlistPrefix, $sourceID, '.xml#', $sourceMeasures2Conc[1]/@xml:id/string(), '.xml?tstamp2=', $sourceMeasures2ConcCount, 'm+0 ')
                                                                                            )
                                                                                            else (
                                                                                                concat($connectionPlistPrefix, $sourceID, '.xml#', $sourceMeasures2Conc[1]/@xml:id/string(), ' ')
                                                                                            )
                                                                                        
                                                                                    )
                                                                
                                                                return
                                                                    $participant
                                                                   
                                                        }
                                                    }
                                    }
                                },
                                element group {
                                    attribute name {"Navigation by text segment"},
                                    element connections {
                                        attribute label {"Text segment"},
                                            for $seg in $segs
                                                let $measureNo := $seg/@n/string()
                                                let $measureLabel := substring-after($seg/@label/string(), 'seg ')
                                                return
                                                    element connection {
                                                        attribute name {$measureLabel},
                                                        attribute plist {
                                                            for $ediConcSource in $ediConcSourcesCollection[matches(.//mei:mei/@xml:id/string(), 'opera_source_medea_T')][.//tei:TEI]
                                                                let $sourceID := if ($ediConcSource/mei:mei)
                                                                                    then ($ediConcSource/mei:mei/@xml:id/string())
                                                                                    else if ($ediConcSource/tei:TEI)
                                                                                    then ($ediConcSource/tei:TEI/@xml:id/string())
                                                                                    else()
                                                                let $participant := if ($ediConcSource/mei:mei)
                                                                                    then (
                                                                                        if (
                                                                                            $ediConcSource//mei:parts
                                                                                        )
                                                                                        then (
                                                                                            concat($connectionPlistPrefix, $sourceID, '.xml#', 'measure_', $ediConcSource//mei:mdiv[@label = $concName]/@xml:id/string(), '_', $measureNo, ' ')
                                                                                        )
                                                                                        else (
                                                                                            let $sourceMeasures2Conc := $ediConcSource//mei:measure[@n = $measureNo and .//ancestor::mei:mdiv[@label = $concName]]
                                                                                            let $sourceMeasures2ConcCount := count($sourceMeasures2Conc)
                                                                                            return
                                                                                                if (
                                                                                                    $sourceMeasures2ConcCount > 1
                                                                                                )
                                                                                                then (
                                                                                                    concat($connectionPlistPrefix, $sourceID, '.xml#', $sourceMeasures2Conc[1]/@xml:id/string(), '.xml?tstamp2=', $sourceMeasures2ConcCount, 'm+0 ')
                                                                                                )
                                                                                                else (
                                                                                                    concat($connectionPlistPrefix, $sourceID, '.xml#', $sourceMeasures2Conc[1]/@xml:id/string(), ' ')
                                                                                                )
                                                                                            
                                                                                        )
                                                                                    )
                                                                                    else if ($ediConcSource/tei:TEI)
                                                                                    then (
                                                                                        
                                                                                    )
                                                                                    else()
                                                                
                                                                return
                                                                    $participant
                                                                   
                                                        }
                                                    }
                                    }
                                }
                            }
                    )
                    else (
                        element connections {
                            attribute label {"Bar"},
                                for $measure in $measures
                                    let $measureID := $measure/@xml:id/string()
                                    let $measureNo := $measure/@label/string()
                                    
                                    return
                                        element connection {
                                            attribute name {$measureNo},
                                            attribute plist {
                                                for $ediConcSource in $ediConcSourcesCollection[.//mei:mei][not(matches(.//mei:mei/@xml:id/string(), 'opera_source_medea_T'))]
                                                    let $sourceID := $ediConcSource/mei:mei/@xml:id/string()
                                                    let $participant := if (
                                                                            $ediConcSource//mei:parts
                                                                        )
                                                                        then (
                                                                            concat($connectionPlistPrefix, $sourceID, '.xml#', 'measure_', $ediConcSource//mei:mdiv[@label = $concName]/@xml:id/string(), '_', $measureNo, ' ')
                                                                        )
                                                                        else (
                                                                            let $sourceMeasures2Conc := $ediConcSource//mei:measure[@label = $measureNo and .//ancestor::mei:mdiv[@label = $concName]]
                                                                            let $sourceMeasures2ConcCount := count($sourceMeasures2Conc)
                                                                            return
                                                                                if (
                                                                                    $sourceMeasures2ConcCount > 1
                                                                                )
                                                                                then (
                                                                                    concat($connectionPlistPrefix, $sourceID, '.xml#', $sourceMeasures2Conc[1]/@xml:id/string(), '.xml?tstamp2=', $sourceMeasures2ConcCount, 'm+0 ')
                                                                                )
                                                                                else (
                                                                                    concat($connectionPlistPrefix, $sourceID, '.xml#', $sourceMeasures2Conc[1]/@xml:id/string(), ' ')
                                                                                )
                                                                            
                                                                        )
                                                    
                                                    return
                                                        $participant
                                                       
                                            }
                                        }
                        }
                    )
                }
        }
