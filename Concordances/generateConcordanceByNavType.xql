xquery version "3.0";

(:~
: make edirom concordances
: single work
: define first: - sources form edition's source Collection?
                - sources form edirom edition file aka sources in navigator?
                - sources by MEI metadata
                
: @author Nikolaos Beer, M.A. (University of Paderborn) for the OPERA project, 2019.
:)

declare default element namespace "http://www.edirom.de/ns/1.3";

declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace functx="http://www.functx.com" at "../Resources/functx.xq";

declare option saxon:output "method=xml";
declare option saxon:output "media-type=text/xml";
declare option saxon:output "omit-xml-declaration=yes";
declare option saxon:output "indent=yes";

(: GLOBALE VARIABLES :)

(:~ The integer part @xml:id of the Edirom edition file as string :)
declare variable $editionID as xs:string := '74338558';

(:~ The prefix part ('edtion-' etc.) of the Edirom edition's @xml:id value :)
declare variable $editionIDPrefix as xs:string := 'edition-';

(:~ Resource fiel name of virtual concordance table (as CSV) (bars mode):)
declare variable $CSVResourceNameBars as xs:string := 'concordance_bars_rawData.csv';

(:~ Resource fiel name of virtual concordance table (as CSV) (lines mode):)
declare variable $CSVResourceNameLines as xs:string := 'concordance_lines_rawData.csv';

(:~ Resource fiel name of virtual concordance table (as CSV) (lines mode):)
declare variable $CSVResourceNameScenes as xs:string := 'concordance_scenes_rawData.csv';

(:~ The relative path to the Edition's contents seen from this xQuery :)
declare variable $basePathToEditionContents as xs:string := '../../';

(:~ Edition contents base path :)
declare variable $pathToEditionContents as xs:string := concat($basePathToEditionContents, $editionIDPrefix, $editionID, '/');

(:~ Edirom edition doc :)
declare variable $editionEdiromDoc as document-node() := doc(concat($pathToEditionContents, $editionIDPrefix, $editionID, '.xml'));

(:~ @xml:id of the MEI work file :)
declare variable $workID as xs:string := 'opera_work_d471efd4-7c6f-4e07-9195-8a6fd713f227';

(:~ Work doc :)
declare variable $workDoc as document-node() := doc(concat($pathToEditionContents, 'works/', $workID, '.xml'));

(:~ @xml:id of the concordance reference source – mostly the edition's "source" :)
declare variable $referenceSourceID as xs:string := 'edirom_source_786a4e99-aacd-459d-a40a-79c894e92497';

(:~ Reference source doc :)
declare variable $refSourceDoc as document-node() := doc(concat($pathToEditionContents, 'sources/', $referenceSourceID, '.xml'));

(:~ Type of concordance. Choose between:
        - generating concordance based on all source files
            found in the edirom edition's sources collection.
            Value: 'sourceCollection'
        - generating concordance based on sources that are
            linkt in the navigator of the edirom edition.
            Value: 'ediromNavigatorSources'
        - generating concordance based on MEI metadata.
            Value: 'meiRelation'
        - generating concordance from list of sources.
            Value: 'sourcesList'
        - read concordance from CSV file.
            Value: 'fromCSV'
:)
declare variable $ediConcType := 'fromCSV';

(:~ Set raw concordance data for bar based concordance :)
declare variable $concRawDataBars := if ($ediConcType = 'fromCSV')
                                        then (functx:lines(unparsed-text(concat($pathToEditionContents, 'resources/Concordance/', $CSVResourceNameBars))))
                                        else ();

(:~ Set raw concordance data for text line based concordance :)
declare variable $concRawDataLines := if ($ediConcType = 'fromCSV')
                                        then (functx:lines(unparsed-text(concat($pathToEditionContents, 'resources/Concordance/', $CSVResourceNameLines))))
                                        else ();

(:~ Specify your own source list here :)
declare variable $sourcesList := ();


declare variable $mdivsReference := if ($ediConcType = 'sourceList')
                                    then ($refSourceDoc//mei:mdiv)
                                    else if ($ediConcType = 'fromCSV')
                                    then (
                                        let $mdivs := for $row in $concRawDataBars[position() > 1]
                                                        let $mdivLabel := tokenize($row, ';')[position() = 3]
                                                        where $mdivLabel != ''
                                                        return
                                                            $mdivLabel
                                        return
                                            distinct-values($mdivs)
                                    )
                                    else();
                        
declare variable $ediConcSourcesCollection :=   
    if ($ediConcType = 'sourceCollection')
    then (
        let $sourcesMEI := collection(concat($pathToEditionContents, 'sources/?select=*.xml'))[.//mei:mei]
        let $sourcesTEI := collection(concat($pathToEditionContents, 'texts/?select=*.xml'))[starts-with(.//tei:TEI/@xml:id/string(), 'TextEdition')]
        return
            ($sourcesMEI, $sourcesTEI)
    )
    (:else if ($ediConcType = 'ediromNavigatorSources')
    then (
        for $target in $editionEdiromDoc//work[@xml:id = $workID]//navigatorItem[starts-with(@targets, $connectionPlistParticipantPrefix)]/@targets
        let $localURI := concat($pathToEditionContents, substring-after($target/string(), concat($editionID, '/')))
        return
            $localURI
    ):)
    else if ($ediConcType = 'meiRelation')
    then () (: ToDo, with respect to TEI :)
    else if ($ediConcType = 'sourcesList')
    then () (: ToDo :)
    (: Data from CSV will be processed later :)
    else if ($ediConcType = 'fromCSV')
    then ()
    else();


(: MODULE FUNCTIONS :)


declare function local:getEdiConcSourcesCollectionFromCSVData($concRawData, $connectionType) {
    for $siglum in local:getSourceSiglaFromCSV($concRawData, $connectionType)
    return
        (collection(concat($pathToEditionContents, 'sources/?select=*.xml'))[.//mei:identifier[@type = 'siglum'] = $siglum] | collection(concat($pathToEditionContents, 'text/?select=*.xml'))[.//tei:fileDesc//tei:title[@type = 'siglum'] = $siglum])
};

(:~
: This function determines whether to read bar based or line based csv raw data
:
: @param $ediConcType               specified concordance type
: @param $connectionType            specified type of connections
: @return CSV raw data
:)

declare function local:getConcRawData($ediConcType, $connectionType){
    if ($ediConcType = 'fromCSV' and $connectionType = 'bars')
    then ($concRawDataBars)
    else if ($ediConcType = 'fromCSV' and $connectionType = 'lines')
    then ($concRawDataLines)
    else if ($ediConcType = 'fromCSV' and $connectionType = 'scenes')
    then ($concRawDataScenes)
    else ()
};




(:~
: This function determines collection paths for music or text sources
:
: @param $ediConcType               specified concordance type
: @param $connectionType            specified type of connections
: @return CSV raw data
:)

declare function local:getConnectionPlistParticipantPrefix($participantSource) {
    if ($participantSource/tei:TEI)
    then (concat('xmldb:exist:///db/contents/', $editionIDPrefix, $editionID, '/text/'))
    else (concat('xmldb:exist:///db/contents/', $editionIDPrefix, $editionID, '/sources/'))
};




(:~
: This function reads all rows from the specified CSV file
:
: @param $ediConcType               specified concordance type
: @param $pathToEditionContents     path to edition's contents
: @param $CSVResourceNameBars           CSV file name
: @return list of source sigla
:)

declare function local:getSourceSiglaFromCSV($ediConcType, $concRawDataBars) {
    if ($ediConcType = 'fromCSV')
    then ((tokenize($concRawDataBars[1], ';')[position() > 4 and position() < 11]))
    else ()
};
                   



(:~
: This function returns the actual source id
:
: @param $participantSource the actual source file
: @return @xml:id
:)

declare function local:getParticipantSourceID($participantSource) {
    root($participantSource)/*/@xml:id
};




(:~
: This function returns a plist participant when MEI contains parts
:
: @param $participantSource         the actual source file
: @param $mdiv                      name of actual mdiv
: @param $connectionParticipantNo   the actual number value of //mdiv/measure/@n
:
: @return String containing the resource name and the virtual measure_mdivID
:)

declare function local:getConnectionPlistParticipantMEIparts($participantSource as node() , $mdiv as xs:string, $connectionParticipantNo as xs:string) {
    concat(local:getParticipantSourceID($participantSource), '.xml#','measure_', $participantSource//mei:mdiv[@label = $mdiv]/@xml:id/string(), '_', $connectionParticipantNo, '')
};




(:~
: This function returns a plist participant uri string
:
: @param $participantSource                     the mei file
: @param $mdiv                                  name of actual mdiv
: @param $connectionParticipantNo               searched measure number
:
: @return Plist participant uri string
:)

declare function local:getConectionPlistParticipantString($participantSource, $mdiv, $connectionParticipantNo) {
    
    let $participantSourceID := local:getParticipantSourceID($participantSource)
    return
        if ($participantSource//mei:parts)
        then (
            if ($participantSource//mei:mdiv[@label = $mdiv])
            then (concat(local:getConnectionPlistParticipantPrefix($participantSource), local:getConnectionPlistParticipantMEIparts($participantSource, $mdiv, $connectionParticipantNo)))
            else ()
        )
        else (
            let $participantSourceMeasures2Connect := if ($participantSource/mei:mei/@xml:id = 'opera_source_6b03f75b-50eb-410b-b729-39c1725bc1cf')
                                                        then ($participantSource//mei:measure[@n = normalize-space($connectionParticipantNo)])
                                                        else if ($participantSource//tei:TEI/@xml:id = 'TextEdition')
                                                        then ($participantSource//tei:l[number(@n) = number(functx:substring-before-if-contains($connectionParticipantNo, ','))] | $participantSource//tei:lb[@type = 'lineNum'][number(@n) = number(functx:substring-before-if-contains($connectionParticipantNo, ','))])
                                                        else ($participantSource//mei:measure[@n = normalize-space($connectionParticipantNo) and .//ancestor::mei:mdiv[@label = $mdiv]])
            return
                if (count($participantSourceMeasures2Connect) > 1)
                then (concat(local:getConnectionPlistParticipantPrefix($participantSource), $participantSourceID, '.xml#', $participantSourceMeasures2Connect[1]/@xml:id/string(), '?tstamp2=', string(count($participantSourceMeasures2Connect)), 'm+0 '))
                else (concat(local:getConnectionPlistParticipantPrefix($participantSource), $participantSourceID, '.xml#', $participantSourceMeasures2Connect/@xml:id/string(), ' '))
        )
};

                                    
(: OPERA-Spezialbehandlung :)



(:let $concordancesSourceList :=    element concordances {
                            for $mdivReference at $pos in $mdivsReference
                                let $concName := $mdivReference/@label/string()
                                let $mdivReferenceMeasures := $mdivReference//mei:measure
                                let $measures := $mdivReferenceMeasures[not(matches(@label, 'seg'))]
                                let $segs := $mdivReferenceMeasures[matches(@label, 'seg')]
                    (\:            where $pos = 2:\)
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
                                                                                                            concat($connectionPlistParticipantPrefix, $sourceID, '.xml#', 'measure_', $ediConcSource//mei:mdiv[@label = $concName]/@xml:id/string(), '_', $measureNo, ' ')
                                                                                                        )
                                                                                                        else (
                                                                                                            let $sourceMeasures2Conc := $ediConcSource//mei:measure[@label = $measureNo and .//ancestor::mei:mdiv[@label = $concName]]
                                                                                                            let $sourceMeasures2ConcCount := count($sourceMeasures2Conc)
                                                                                                            return
                                                                                                                if (
                                                                                                                    $sourceMeasures2ConcCount > 1
                                                                                                                )
                                                                                                                then (
                                                                                                                    concat($connectionPlistParticipantPrefix, $sourceID, '.xml#', $sourceMeasures2Conc[1]/@xml:id/string(), '.xml?tstamp2=', $sourceMeasures2ConcCount, 'm+0 ')
                                                                                                                )
                                                                                                                else (
                                                                                                                    concat($connectionPlistParticipantPrefix, $sourceID, '.xml#', $sourceMeasures2Conc[1]/@xml:id/string(), ' ')
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
                                                                                                                concat($connectionPlistParticipantPrefix, $sourceID, '.xml#', 'measure_', $ediConcSource//mei:mdiv[@label = $concName]/@xml:id/string(), '_', $measureNo, ' ')
                                                                                                            )
                                                                                                            else (
                                                                                                                let $sourceMeasures2Conc := $ediConcSource//mei:measure[@n = $measureNo and .//ancestor::mei:mdiv[@label = $concName]]
                                                                                                                let $sourceMeasures2ConcCount := count($sourceMeasures2Conc)
                                                                                                                return
                                                                                                                    if (
                                                                                                                        $sourceMeasures2ConcCount > 1
                                                                                                                    )
                                                                                                                    then (
                                                                                                                        concat($connectionPlistParticipantPrefix, $sourceID, '.xml#', $sourceMeasures2Conc[1]/@xml:id/string(), '.xml?tstamp2=', $sourceMeasures2ConcCount, 'm+0 ')
                                                                                                                    )
                                                                                                                    else (
                                                                                                                        concat($connectionPlistParticipantPrefix, $sourceID, '.xml#', $sourceMeasures2Conc[1]/@xml:id/string(), ' ')
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
                                                                                                concat($connectionPlistParticipantPrefix, $sourceID, '.xml#', 'measure_', $ediConcSource//mei:mdiv[@label = $concName]/@xml:id/string(), '_', $measureNo, ' ')
                                                                                            )
                                                                                            else (
                                                                                                let $sourceMeasures2Conc := $ediConcSource//mei:measure[@label = $measureNo and .//ancestor::mei:mdiv[@label = $concName]]
                                                                                                let $sourceMeasures2ConcCount := count($sourceMeasures2Conc)
                                                                                                return
                                                                                                    if (
                                                                                                        $sourceMeasures2ConcCount > 1
                                                                                                    )
                                                                                                    then (
                                                                                                        concat($connectionPlistParticipantPrefix, $sourceID, '.xml#', $sourceMeasures2Conc[1]/@xml:id/string(), '.xml?tstamp2=', $sourceMeasures2ConcCount, 'm+0 ')
                                                                                                    )
                                                                                                    else (
                                                                                                        concat($connectionPlistParticipantPrefix, $sourceID, '.xml#', $sourceMeasures2Conc[1]/@xml:id/string(), ' ')
                                                                                                    )
                                                                                                
                                                                                            )
                                                                        
                                                                        return
                                                                            $participant
                                                                           
                                                                }
                                                            }
                                            }
                                        )
                                    }
                            }:)


let $concordancesCSVFile := element concordances {
                                element concordance {
                                    attribute name {'Navigation by number &amp; bar'},
                                    element groups {
                                        for $mdiv in $mdivsReference
                                        return
                                            element group {
                                                attribute name {$mdiv},
                                                element connections {
                                                    attribute label {'Bar'},
                                                    let $CSVResourceName := $CSVResourceNameBars
                                                    for $row in $concRawDataBars[position() > 1][tokenize(., ';')[position() = 3] = $mdiv]
                                                    let $rowT := tokenize($row, ';')
                                                    let $connectionNo := $rowT[position() = 4]
                                                    let $connectionParticipantNos := $rowT[position() > 4 and position() < 11]
                                                    (: 5(1) = ME | 6(2) = A | 7(3) = WO | 8(4) = TE | 9(5) = T | 10(6) = T1 :)
                                                    let $plist :=   for $connectionParticipantNo at $pos in $connectionParticipantNos
                                                                    let $participantSource := $ediConcSourcesCollection[$pos]
                                                                    where $pos < 6 and normalize-space($connectionParticipantNo) != ''
                                                                    return
                                                                        local:getConectionPlistParticipantString($participantSource, $mdiv, $connectionParticipantNo)
                                                    return
                                                        element connection {
                                                            attribute name {$connectionNo},
                                                            attribute plist {$plist}
                                                        }
                                                }
                                            }
                                    }
                                    
                                        
                                },
                                element concordance {
                                    attribute name {'Navigation by scene/text line'},
                                    element groups {
                                        element group {
                                            attribute name {'Scene'},
                                            element connections {
                                            }
                                        },
                                        element group {
                                            attribute name {'Text line'},
                                            element connections {
                                                (:attribute label {'Text line'},
                                                let $CSVResourceName := $CSVResourceNameLines
                                                
                                                for $row in :)
                                            }
                                        }
                                    }
                                }
                            }
                                        

return
$concordancesCSVFile
(:$ediConcSourcesCollection:)
