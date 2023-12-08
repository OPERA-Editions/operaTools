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
declare variable $editionID as xs:string := '74338566';

(:~ The prefix part ('edtion-' etc.) of the Edirom edition's @xml:id value :)
declare variable $editionIDPrefix as xs:string := 'edition-';

(:~ Resource fiel name of virtual concordance table (as CSV) (bars mode):)
declare variable $CSVResourceNameBars as xs:string := 'concordance_bars_rawData.csv';

(:~ Resource fiel name of virtual concordance table (as CSV) (lines mode):)
declare variable $CSVResourceNameLines as xs:string := 'concordance_lines_rawData.csv';

(:~ Resource fiel name of virtual concordance table (as CSV) (scenes mode):)
declare variable $CSVResourceNameScenes as xs:string := 'concordance_scenes_rawData.csv';

(:~ The relative path to the Edition's contents seen from this xQuery :)
declare variable $basePathToEditionContents as xs:string := '../../';

(:~ Edition contents base path :)
declare variable $pathToEditionContents as xs:string := concat($basePathToEditionContents, $editionIDPrefix, $editionID, '/');

(:~ Edirom edition doc :)
declare variable $editionEdiromDoc as document-node() := doc(concat($pathToEditionContents, $editionIDPrefix, $editionID, '.xml'));

(:~ @xml:id of the MEI work file :)
declare variable $workID as xs:string := 'opera_work_04300c1e-10ad-408e-9665-aff63edf3e1f_TE';

(:~ Work doc :)
declare variable $workDoc as document-node() := doc(concat($pathToEditionContents, 'works/', $workID, '.xml'));

(:~ @xml:id of the concordance reference source – mostly the edition's "source" :)
declare variable $referenceSourceID as xs:string := 'opera_source_e12fba06-b908-42db-9442-c2c8d0075fbc';

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
declare variable $ediConcType as xs:string := 'fromCSV';

(:~ Set raw concordance data for bar based concordance from CSV :)
declare variable $concRawDataBars := if ($ediConcType = 'fromCSV')
                                        then (functx:lines(unparsed-text(concat($pathToEditionContents, 'resources/concordance/TE/', $CSVResourceNameBars))))
                                        else ();

(:~ Set raw concordance data for text line based concordance from CSV :)
declare variable $concRawDataLines := if ($ediConcType = 'fromCSV')
                                        then (functx:lines(unparsed-text(concat($pathToEditionContents, 'resources/concordance/TE/', $CSVResourceNameLines))))
                                        else ();
                                        
(:~ Set raw concordance data for scenes based concordance from CSV :)
declare variable $concRawDataScenes := if ($ediConcType = 'fromCSV')
                                        then (functx:lines(unparsed-text(concat($pathToEditionContents, 'resources/concordance/TE/', $CSVResourceNameScenes))))
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
(:        (collection(concat($pathToEditionContents, 'sources/?select=*.xml'))[.//mei:identifier[@type = 'siglum'] = $siglum] | collection(concat($pathToEditionContents, 'texts/?select=*.xml'))[.//tei:fileDesc//tei:title[@type = 'siglum'] = $siglum]):)
        (collection(concat($pathToEditionContents, 'sources/?select=*.xml'))[.//mei:identifier[@type = 'siglum'] = $siglum] | collection(concat($pathToEditionContents, 'texts/?select=*TextEdition.xml')))

(:        $siglum:)

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
    then (concat('xmldb:exist:///db/contents/', $editionIDPrefix, $editionID, '/texts/'))
    else (concat('xmldb:exist:///db/contents/', $editionIDPrefix, $editionID, '/sources/'))
};




(:~
: This function reads all rows from the specified CSV file
:
: @param $ediConcType               specified concordance type
: @param $pathToEditionContents     path to edition's contents
: @param $CSVResourceNameBars       CSV file name
: @return list of source sigla
:)

declare function local:getSourceSiglaFromCSV($concRawData, $connectionType) {
    if ($connectionType = 'scenes')
    then (tokenize($concRawData[1], ';')[position() > 3 and position() < 6])
    else (tokenize($concRawData[1], ';')[position() > 5 and position() < 8])
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


declare function local:fillLineNumberZeros($number as xs:string) {
    let $lineNumber := number($number)
    
    
    return 
        if (contains($number, 'app') or contains($number, "'"))
        then ($number)
        else if ($lineNumber < 10)
        then (concat('000', $lineNumber))
        else if ($lineNumber < 100)
        then (concat('00', $lineNumber))
        else if ($lineNumber < 1000)
        then (concat('0', $lineNumber))
        else ($lineNumber)
};

(:~
: This function returns a plist participant uri string
:
: @param $participantSource                     the mei/tei file
: @param $mdiv                                  name of actual mdiv
: @param $connectionParticipantNo               searched measure number
:
: @return Plist participant uri string
:)

declare function local:getConectionPlistParticipantString($participantSource, $mdiv, $connectionParticipantNo, $connectionType) {
    let $participantSourceID := local:getParticipantSourceID($participantSource)
    (:return concat($participantSourceID, '-', $connectionParticipantNo):)
    return
        (: Hat die Quelle Stimmen?       :)
        if ($participantSource//mei:parts)
        then (
            if ($participantSource//mei:mdiv[@label = $mdiv])
            then (concat(local:getConnectionPlistParticipantPrefix($participantSource), local:getConnectionPlistParticipantMEIparts($participantSource, $mdiv, $connectionParticipantNo)))
            else ()
        )
        else (
            let $participantSourceMeasures2Connect :=   
                                                        (: Steffani Special case: appendix links to previous mdiv :)
                                                        (: also Steffani: I,15 - No. 18 Aria e Ritornello: 'I,14 - No. 17 Aria e Ritornello' :)
                                                        if (contains($connectionParticipantNo, ':'))
                                                        then (
                                                            (:if (functx:number-of-matches($connectionParticipantNo, ',') = 2):)
                                                            if (contains($connectionParticipantNo, ', '))
                                                            then (
                                                                let $connectionParticipantNoT := tokenize($connectionParticipantNo, ', ')
                                                                return
                                                                    for $p in $connectionParticipantNoT
                                                                    return
                                                                        
                                                                        if (contains($p, ':'))
                                                                        then (
                                                                            
                                                                            $participantSource//mei:measure[.//ancestor::mei:mdiv[@label = normalize-space(substring-before($p, ':'))]][@n = normalize-space(substring-after($p, ':'))]
                                                                        )
                                                                        else (
                                                                            $participantSource//mei:measure[@n = normalize-space($p)]
                                                                        )
                                                            )
                                                            else (
                                                                $participantSource//mei:measure[.//ancestor::mei:mdiv[@label = normalize-space(substring-before($connectionParticipantNo, ':'))]][@n = normalize-space(substring-after($connectionParticipantNo, ':'))]
(:                                                                normalize-space(substring-before($connectionParticipantNo, ':')):)

                                                            )
                                                        )
                                                        
                                                        (:(\: LiaV: Special case: Text only Air 30 in bar concordance showing text lines of ME :\) 
                                                        else if ($mdiv = 'Air 30' and $connectionType = 'bars')
                                                        then (
                                                            if ($participantSource/mei:mei/@xml:id = 'opera_edition_3578ef42-491f-4bc1-a426-728553f3cdba')
                                                            then ($participantSource//mei:mdiv[@label = 'Air 30']//mei:measure[1])
                                                            else if ($participantSource//tei:TEI/@xml:id = 'TextEdition')
                                                            then ($participantSource//tei:l[number(@n) = number(functx:substring-before-if-contains($connectionParticipantNo, ','))] | $participantSource//tei:lb[@type = 'lineNum'][number(@n) = number(functx:substring-before-if-contains($connectionParticipantNo, ','))])
                                                            else if ($participantSource/mei:mei/@xml:id = 'opera_source_6b03f75b-50eb-410b-b729-39c1725bc1cf')
                                                            then ($participantSource//mei:measure[@n = $connectionParticipantNo])
                                                            else ()
                                                        )
                                                        (\: Special case: Text lines of ME in text line concordance :\)
                                                        else if ($connectionType = 'lines' and $mdiv = 'Air 30' and $participantSource/mei:mei/@xml:id = 'opera_edition_3578ef42-491f-4bc1-a426-728553f3cdba')
                                                        then ($participantSource//mei:mdiv[@label = 'Text lines']//mei:measure[@n = normalize-space($connectionParticipantNo)])
                                                        else if ($connectionType = 'lines' and $mdiv = '' and $participantSource/mei:mei/@xml:id = 'opera_edition_3578ef42-491f-4bc1-a426-728553f3cdba')
                                                        then ($participantSource//mei:mdiv[@label = 'Text lines']//mei:measure[@n = normalize-space($connectionParticipantNo)]):)
                                                        
                                                        (: LiaV: opera_source_6b03f75b-50eb-410b-b729-39c1725bc1c: T; opera_source_3f9ceb69-e909-4fcd-aaeb-06fd3d02e780: T1 :)
                                                        (: Steffani: opera_source_987507b4-a1ac-4de4-a9bb-173ea86d8449: T (ME) :)
                                                        (: Steffani: opera_source_e12fba06-b908-42db-9442-c2c8d0075fbc: T-TE :)
                                                        else if ($participantSource/mei:mei/@xml:id = 'opera_source_e12fba06-b908-42db-9442-c2c8d0075fbc')
                                                        then (
                                                            if (contains($connectionParticipantNo, ','))
                                                            then (
                                                                let $connectionParticipantNoT := tokenize($connectionParticipantNo, ', ')
                                                                return
                                                                    for $p in $connectionParticipantNoT
                                                                    return
                                                                        $participantSource//mei:measure[@n = concat('l. ', normalize-space($p))]
                                                            
                                                            )
                                                            (:else ($participantSource//mei:measure[@n = normalize-space(concat('l. ', $connectionParticipantNo))]):)
                                                            else ($participantSource//mei:measure[@n = normalize-space($connectionParticipantNo)])
                                                        )
                                                        
                                                        (:(\: LiaV: opera_edition_3578ef42-491f-4bc1-a426-728553f3cdba: ME; opera_source_786a4e99-aacd-459d-a40a-79c894e92497: A :\)
                                                        (\: Steffani: opera_source_a8ee1f84-fc0f-4d21-a56f-72e4f93f91c4: A; edirom_source_947bf706-3c36-41fd-9f09-5b995d067a74: B :\)
                                                        else if (($participantSource/mei:mei/@xml:id = 'opera_edition_3578ef42-491f-4bc1-a426-728553f3cdba' or $participantSource/mei:mei/@xml:id = 'opera_source_a8ee1f84-fc0f-4d21-a56f-72e4f93f91c4' or $participantSource/mei:mei/@xml:id = 'edirom_source_947bf706-3c36-41fd-9f09-5b995d067a74') and contains($connectionParticipantNo, ','))
                                                        then (
                                                            if (contains(substring-before($connectionParticipantNo, ','), '-'))
                                                            then (
                                                                $participantSource//mei:measure[.//ancestor::mei:mdiv[@label = $mdiv]][number(@n) >= number(substring-before($connectionParticipantNo, '-')) and number(@n) <= number(substring-before(substring-after($connectionParticipantNo, '-'), ','))]
                                                            )
                                                            else(
(\:                                                                $participantSource//mei:measure[.//ancestor::mei:mdiv[@label = $mdiv]][@n = normalize-space(substring-before($connectionParticipantNo, ','))]:\)
                                                                let $connectionParticipantNoT := tokenize($connectionParticipantNo, ', ')
                                                                return
                                                                    for $p in $connectionParticipantNoT
                                                                    return
                                                                        $participantSource//mei:measure[@n = normalize-space($p)]
                                                            )
                                                        ):)
                                                        
                                                        (: LiaV: opera_edition_3578ef42-491f-4bc1-a426-728553f3cdba: ME; opera_source_786a4e99-aacd-459d-a40a-79c894e92497: A :)
                                                        (: Steffani: opera_source_a8ee1f84-fc0f-4d21-a56f-72e4f93f91c4: A; edirom_source_947bf706-3c36-41fd-9f09-5b995d067a74: B :)
                                                        else if (($participantSource/mei:mei/@xml:id = 'opera_edition_3578ef42-491f-4bc1-a426-728553f3cdba' or $participantSource/mei:mei/@xml:id = 'opera_source_a8ee1f84-fc0f-4d21-a56f-72e4f93f91c4' or $participantSource/mei:mei/@xml:id = 'edirom_source_947bf706-3c36-41fd-9f09-5b995d067a74') and contains($connectionParticipantNo, '-'))
                                                        then (
                                                            $participantSource//mei:measure[.//ancestor::mei:mdiv[@label = $mdiv]][number(@n) >= number(substring-before($connectionParticipantNo, '-')) and number(@n) <= number(substring-after($connectionParticipantNo, '-'))]
                                                        )
                                                        
                                                        else if ($participantSource//tei:TEI/@xml:id = 'TextEdition')
                                                        (:then ($participantSource//tei:l[number(@n) = number(functx:substring-before-if-contains($connectionParticipantNo, ','))] | $participantSource//tei:lb[@type = 'lineNum'][number(@n) = number(functx:substring-before-if-contains($connectionParticipantNo, ','))]):)
                                                        then ($participantSource//tei:l[@xml:id = concat('TE-HenricoLeone_l_', local:fillLineNumberZeros(functx:substring-before-if-contains($connectionParticipantNo, ',')))] | $participantSource//tei:lb[@type = 'lineNum'][number(@n) = number(functx:substring-before-if-contains($connectionParticipantNo, ','))])
(:                                                        then ("TE"):)
                                                        
(:                                                        else ($participantSource//mei:measure[.//ancestor::mei:mdiv[@label = $mdiv]][@n = normalize-space($connectionParticipantNo)]):)
(:                                                        else ($participantSource//mei:measure[.//ancestor::mei:mdiv[@label = $mdiv]][@n = normalize-space($connectionParticipantNo)]):)
                                                        else()
(:                                                        else ($mdiv):)
(:            return $participantSourceMeasures2Connect:)
            return
(:                $participantSourceID:)
(:                $participantSource//@xml:id:)
(:                $participantSourceMeasures2Connect:)
                if (count($participantSourceMeasures2Connect) > 1)
                then (concat(local:getConnectionPlistParticipantPrefix($participantSource), $participantSourceID, '.xml#', $participantSourceMeasures2Connect[1]/@xml:id/string(), '?tstamp2=', string(count($participantSourceMeasures2Connect) - 1), 'm+0 '))
                else if (count($participantSourceMeasures2Connect) = 1)
                then (concat(local:getConnectionPlistParticipantPrefix($participantSource), $participantSourceID, '.xml#', $participantSourceMeasures2Connect/@xml:id/string(), ' '))
                else ("x")
        )
};




(:~
: This function returns an element
:
: @param $participantSource                     the tei file
: @param $connectionParticipantNo               searched measure number
:
: @return element
:)

declare function local:getTextSourceSceneParticipant($participantSource, $connectionParticipantName) {
    (:let $act := local:roman2arabic(substring-after(substring-before($connectionParticipantName, ','), 'Atto '))
    let $scene := local:roman2arabic(substring-after($connectionParticipantName, 'Scena ')):)
    let $act := substring-after(substring-before($connectionParticipantName, ','), 'Atto ')
    let $scene := substring-after($connectionParticipantName, 'Scena ')
    
    return
(:    concat ($connectionParticipantName, ' [', $act, ' ', $scene, ']'):)
        $participantSource//tei:div[@type = 'act'][@n = $act]/tei:div[@type = 'scene'][@n = $scene]/tei:head[@type = 'scene']


};




declare function local:roman2arabic($item) {
    switch ($item)
                            case 'I' return '1'
                            case 'II' return '2'
                            case 'III' return '3'
                            case 'IV' return '4'
                            case 'V' return '5'
                            case 'VI' return '6'
                            case 'VII' return '7'
                            case 'VIII' return '8'
                            case 'IX' return '9'
                            case 'X' return '10'
                            case 'XI' return '11'
                            case 'XII' return '12'
                            case 'XIII' return '13'
                            default return ''

};
declare function local:arabic2roman($item) {
    switch ($item)
                            case '1' return 'I'
                            case '2' return 'II'
                            case '3' return 'III'
                            case '4' return 'IV'
                            case '5' return 'V'
                            case '6' return 'VI'
                            case '7' return 'VII'
                            case '8' return 'VIII'
                            case '9' return 'IX'
                            case '10' return 'X'
                            case '11' return 'XI'
                            case '12' return 'XII'
                            case '13' return 'XIII'
                            case '14' return 'XIV'
                            
                            case '15' return 'XV'
                            case '16' return 'XVI'
                            case '17' return 'XVII'
                            case '18' return 'XVIII'
                            case '19' return 'XIX'
                            case '20' return 'XX'
                            case '21' return 'XXI'
                            case '22' return 'XII'
                            case '23' return 'XIII'
                            case '24' return 'XXIV'
                            default return ''

};


(:~
: This function returns a plist participant uri string for scene connections
:
: @param $participantSource                     the mei/tei file
: @param $mdiv                                  name of actual mdiv
: @param $connectionParticipantName             searched scene
:
: @return Plist participant uri string
:)

declare function local:getSceneConectionPlistParticipantString($participantSource, $mdiv, $connectionParticipantName) {
    let $participantSourceID := local:getParticipantSourceID($participantSource)
    let $participantSourceMeasures2Connect := if ($participantSource//tei:TEI/@xml:id = 'TextEdition')
                                                then (local:getTextSourceSceneParticipant($participantSource, $connectionParticipantName))
                                                else ($participantSource//mei:measure[.//ancestor::mei:mdiv[@label = $mdiv]][@label = normalize-space($connectionParticipantName)])
    return
(:    $participantSourceMeasures2Connect:)
(:    count($participantSourceMeasures2Connect):)
        if (count($participantSourceMeasures2Connect) > 1)
                then (concat(local:getConnectionPlistParticipantPrefix($participantSource), $participantSourceID, '.xml#', $participantSourceMeasures2Connect[1]/@xml:id/string(), '?tstamp2=', string(count($participantSourceMeasures2Connect) - 1), 'm+0 '))
                else if (count($participantSourceMeasures2Connect) = 1)
                then (concat(local:getConnectionPlistParticipantPrefix($participantSource), $participantSourceID, '.xml#', $participantSourceMeasures2Connect/@xml:id/string(), ' '))
                else ()
                

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


let $testOutput := 
                                        let $connectionType := 'bars'
                                        let $concRawData := local:getConcRawData($ediConcType, $connectionType)
                                        let $ediConcSourcesCollection := local:getEdiConcSourcesCollectionFromCSVData($concRawData, $connectionType)
                                        (: sigla :)
                                        let $test := local:getSourceSiglaFromCSV($concRawData, $connectionType)
    return $ediConcSourcesCollection
(:return $test:)

let $concordancesCSVFile := element concordances {

                                element concordance {
                                    attribute name {'Navigation by scene/text line'},
                                    element groups {
                                        (: Steffani TE: Naviagtion by scenes :)
                                        (:element group {
                                            attribute name {'scene'},
                                            element connections {
                                            let $connectionType := 'scenes'
                                            let $concRawData := local:getConcRawData($ediConcType, $connectionType)
                                            let $ediConcSourcesCollection := local:getEdiConcSourcesCollectionFromCSVData($concRawData, $connectionType)
                                            
                                            (\: TBa 2022-10-06: $scenes never used... :\)
                                            (\:let $scenes := for $row at $pos in $concRawData[position() > 1][tokenize(., ';')[position() = 2] != '']
                                                                let $rowT := tokenize($row, ';')[position() >= 1 and position() <= 2]
                                                                return
                                                                    concat($rowT[1], ';', $rowT[2]):\)
                                            
                                            for $row in $concRawData[position() > 1]
                                                    let $rowT := tokenize($row, ';')
                                                    let $act := normalize-space($rowT[1])
                                                    let $scene := local:arabic2roman(normalize-space($rowT[2]))
                                                    let $mdiv := 'Acts and Scenes'
                                                    let $connectionName := concat('Atto ', $act, ', Scena ', $scene)
                                                    let $connectionParticipantNames := $rowT[position() > 3 and position() < 6]
                                                    
                                                    
                                                    
                                                    
                                                    let $plist := for $connectionParticipantName at $pos in $connectionParticipantNames
                                                                    let $participantSource := $ediConcSourcesCollection[$pos]
                                                                    (\: $pos is max count of sources/$connectionParticipantNos :\)
                                                                    where $pos < 8 and normalize-space($connectionParticipantName) != ''
                                                                    return
(\:                                                                    $pos:\)
(\:                                                                        concat($participantSource/*/@xml:id/string(), ', ', $mdiv, ', ', $connectionParticipantName):\)
                                                                        local:getSceneConectionPlistParticipantString($participantSource, $mdiv, $connectionParticipantName)
                                            
                                            (\:let $scenes := for $row at $pos in $concRawData[position() > 1][tokenize(., ';')[position() = 2] != '']
                                                                let $rowT := tokenize($row, ';')[position() >= 1 and position() <= 2]
                                                                return
                                                                    concat($rowT[1], ';', $rowT[2])
                                            
                                            for $scene at $pos in distinct-values($scenes)
                                                let $sceneT := tokenize($scene, ';')
                                                let $act := $sceneT[1]
                                                let $scene := $sceneT[2]
                                                let $connectionName := concat('Act ', $act, ', Scene ', $scene)
                                                let $connectionRow := for $row at $pos in $concRawData[tokenize(., ';')[position() = 1] = $act and tokenize(., ';')[position() = 2] = $scene][1]
                                                                        return
                                                                            $row
                                                let $connectionRowT := tokenize($connectionRow, ';')
                                                let $connectionParticipantNos := $connectionRowT[position() > 2 and position() < 7]
                                                let $plist := for $connectionParticipantNo at $pos in $connectionParticipantNos
                                                                    let $participantSource := $ediConcSourcesCollection[$pos]
                                                                    where $pos < 3 and normalize-space($connectionParticipantNo) != ''
                                                                    return
                                                                        (\:local:getConectionPlistParticipantString($participantSource, $mdiv, $connectionParticipantNo):\)
                                                                        let $participantSourceID := local:getParticipantSourceID($participantSource)
                                                                        return
                                                                            let $participantSourceMeasures2Connect := if ($participantSource/mei:mei/@xml:id = 'opera_source_6b03f75b-50eb-410b-b729-39c1725bc1cf')
                                                                                                                        then ($participantSource//mei:measure[@n = normalize-space($connectionParticipantNo)])
                                                                                                                        else if ($participantSource//tei:TEI/@xml:id = 'TextEdition')
                                                                                                                        then (
                                                                                                                            $participantSource//tei:l[number(@n) = number(functx:substring-before-if-contains($connectionParticipantNo, ','))]//ancestor::*/tei:head[@type = 'scene'] |
                                                                                                                            $participantSource//tei:lb[@type = 'lineNum'][number(@n) = number(functx:substring-before-if-contains($connectionParticipantNo, ','))]//ancestor::*/tei:head[@type = 'scene']
                                                                                                                            )
                                                                                                                        else ()
                                                                            return
                                                                                if (count($participantSourceMeasures2Connect) > 1)
                                                                                    then (concat(local:getConnectionPlistParticipantPrefix($participantSource), $participantSourceID, '.xml#', $participantSourceMeasures2Connect[1]/@xml:id/string(), '?tstamp2=', string(count($participantSourceMeasures2Connect) - 1), 'm+0 '))
                                                                                    else (concat(local:getConnectionPlistParticipantPrefix($participantSource), $participantSourceID, '.xml#', $participantSourceMeasures2Connect/@xml:id/string(), ' '))
                                                                                                     :\)               
                                                return
                                                    element connection {
(\:                                                        attribute test {concat(string($ediConcSourcesCollection[2]//mei:identifier[@type='siglum']), $ediConcSourcesCollection[1]//tei:TEI[@xml:id])},:\)
                                                        (\:attribute test {$ediConcSourcesCollection[1]},
                                                        attribute test2 {$ediConcSourcesCollection[2]},:\)
                                                        attribute name {$connectionName},
                                                        attribute plist {$plist}
                                                        }
                                            }
                                        }:)
                                        
                                        
                                        
                                        (: Steffani TE: Navgiation by text line :)
                                        element group {
                                            attribute name {'Text line'},  (: Navigation by text line :)
                                            element connections {
                                                let $connectionType := 'lines'
                                                let $concRawData := local:getConcRawData($ediConcType, $connectionType)
                                                let $ediConcSourcesCollection := local:getEdiConcSourcesCollectionFromCSVData($concRawData, $connectionType)
                                                return
(:                                                    attribute ediConcSourcesCollection {$ediConcSourcesCollection}:)
                                                    (:attribute concRawData {$concRawData}:)
                                                    
                                                for $row in $concRawData[position() > 1]
                                                    let $rowT := tokenize($row, ';')
                                                    let $mdiv := $rowT[position() = 4]
                                                    let $connectionNo := $rowT[position() = 5]
                                                    let $connectionParticipantNos := $rowT[position() > 5 and position() < 8]
                                                    let $plist := for $connectionParticipantNo at $pos in $connectionParticipantNos
                                                                    let $participantSource := $ediConcSourcesCollection[$pos]
                                                                    where $pos < 8 and normalize-space($connectionParticipantNo) != ''
                                                                    return
                                                                        local:getConectionPlistParticipantString($participantSource, $mdiv, $connectionParticipantNo, $connectionType)
                                                        return
                                                            element connection {
(:                                                                attribute rowT {$rowT},:)
(:                                                                attribute connectionParticipantNos {$connectionParticipantNos},:)
(:                                                                attribute ediConcSourcesCollection {$ediConcSourcesCollection},:)
(:                                                                attribute mdiv {$mdiv},:)
                                                                attribute name {$connectionNo},
                                                                attribute plist {$plist}
                                                                }
                                            }
                                        }
                                        
                                        
                                        
                                        
                                        
                                        
                                        
                                        
                                        
                                    }
                                }
                                (: following: trash? :)
                                (:element concordance {
                                    attribute name {'Navigation by lines'},
                                    element groups {
                                        let $connectionType := 'bars'
                                        let $concRawData := local:getConcRawData($ediConcType, $connectionType)
                                        let $ediConcSourcesCollection := local:getEdiConcSourcesCollectionFromCSVData($concRawData, $connectionType)
                                        for $mdiv in $mdivsReference
                                        return
                                            element group {
                                                attribute name {$mdiv},
                                                element connections {
                                                    attribute label {if ($mdiv = 'Air 30') then ('Text line') else ('Bar')},
                                                    for $row in $concRawData[position() > 1][tokenize(., ';')[position() = 3] = $mdiv]
                                                    let $rowT := tokenize($row, ';')
                                                    let $connectionNo := $rowT[position() = 4]
                                                    let $connectionParticipantNos := $rowT[position() > 5 and position() < 9]
                                                    (\: LiaV: 5(1) = ME | 6(2) = A | 7(3) = WO | 8(4) = TE | 9(5) = T | 10(6) = T1 :\)
                                                    (\: Steffani: 5(1) = ME | 6(2) = A | 7(3) = B | 8(4) = T (ME)    // | 9(5) = T | 10(6) = T1 :\)
                                                    let $plist :=   for $connectionParticipantNo at $pos in $connectionParticipantNos
(\:                                                    return $connectionParticipantNos:\)
                                                                    let $participantSource := $ediConcSourcesCollection[$pos]
                                                                    where $pos < 7 and normalize-space($connectionParticipantNo) != ''
                                                                    return
                                                                        local:getConectionPlistParticipantString($participantSource, $mdiv, $connectionParticipantNo, $connectionType)
(\:                                                    return $plist:\)
                                                    return
                                                        element connection {
                                                            attribute name {if ($mdiv = 'Air 30') then (concat('[Text only, l.', $connectionNo, ']')) else ($connectionNo)},
                                                            attribute plist {$plist}
                                                        }
                                                }
                                            }
                                    }
                                    
                                        
                                }:)
                                
                                (:element concordance {
                                    attribute name {'Navigation by air &amp; bar'},
                                    element groups {
                                        let $connectionType := 'bars'
                                        let $concRawData := local:getConcRawData($ediConcType, $connectionType)
                                        let $ediConcSourcesCollection := local:getEdiConcSourcesCollectionFromCSVData($concRawData, $connectionType)
                                        for $mdiv in $mdivsReference
                                        return
                                            element group {
                                                attribute name {$mdiv},
                                                element connections {
                                                    attribute label {if ($mdiv = 'Air 30') then ('Text line') else ('Bar')},
                                                    for $row in $concRawData[position() > 1][tokenize(., ';')[position() = 3] = $mdiv]
                                                    let $rowT := tokenize($row, ';')
                                                    let $connectionNo := $rowT[position() = 4]
                                                    let $connectionParticipantNos := $rowT[position() > 5 and position() < 9]
                                                    (\: LiaV: 5(1) = ME | 6(2) = A | 7(3) = WO | 8(4) = TE | 9(5) = T | 10(6) = T1 :\)
                                                    (\: Steffani: 5(1) = ME | 6(2) = A | 7(3) = B | 8(4) = T (ME)    // | 9(5) = T | 10(6) = T1 :\)
                                                    let $plist :=   for $connectionParticipantNo at $pos in $connectionParticipantNos
(\:                                                    return $connectionParticipantNos:\)
                                                                    let $participantSource := $ediConcSourcesCollection[$pos]
                                                                    where $pos < 7 and normalize-space($connectionParticipantNo) != ''
                                                                    return
                                                                        local:getConectionPlistParticipantString($participantSource, $mdiv, $connectionParticipantNo, $connectionType)
(\:                                                    return $plist:\)
                                                    return
                                                        element connection {
                                                            attribute name {if ($mdiv = 'Air 30') then (concat('[Text only, l.', $connectionNo, ']')) else ($connectionNo)},
                                                            attribute plist {$plist}
                                                        }
                                                }
                                            }
                                    }
                                    
                                        
                                }:)(:,
                                element concordance {
                                    attribute name {'Navigation by scene/text line'},
                                    element groups {
                                        element group {
                                            attribute name {'Scene'},
                                            element connections {
                                            let $connectionType := 'scenes'
                                            let $concRawData := local:getConcRawData($ediConcType, $connectionType)
                                            let $ediConcSourcesCollection := local:getEdiConcSourcesCollectionFromCSVData($concRawData, $connectionType)
                                            
                                            let $scenes := for $row at $pos in $concRawData[position() > 1][tokenize(., ';')[position() = 2] != '']
                                                                let $rowT := tokenize($row, ';')[position() >= 1 and position() <= 2]
                                                                return
                                                                    concat($rowT[1], ';', $rowT[2])
                                            
                                            for $row in $concRawData[position() > 1]
                                                    let $rowT := tokenize($row, ';')
                                                    let $act := normalize-space($rowT[1])
                                                    let $scene := normalize-space($rowT[2])
                                                    let $mdiv := 'Acts and Scenes'
                                                    let $connectionName := concat('Act ', $act, ', Scene ', $scene)
                                                    let $connectionParticipantNames := $rowT[position() > 2 and position() < 8]
                                                    let $plist := for $connectionParticipantName at $pos in $connectionParticipantNames
                                                                    let $participantSource := $ediConcSourcesCollection[$pos]
                                                                    (\: $pos is max count of sources/$connectionParticipantNos :\)
                                                                    where $pos < 6 and normalize-space($connectionParticipantName) != ''
                                                                    return
(\:                                                                        concat($participantSource/*/@xml:id/string(), ', ', $mdiv, ', ', $connectionParticipantName):\)
                                                                        local:getSceneConectionPlistParticipantString($participantSource, $mdiv, $connectionParticipantName)
                                            
                                            (\:let $scenes := for $row at $pos in $concRawData[position() > 1][tokenize(., ';')[position() = 2] != '']
                                                                let $rowT := tokenize($row, ';')[position() >= 1 and position() <= 2]
                                                                return
                                                                    concat($rowT[1], ';', $rowT[2])
                                            
                                            for $scene at $pos in distinct-values($scenes)
                                                let $sceneT := tokenize($scene, ';')
                                                let $act := $sceneT[1]
                                                let $scene := $sceneT[2]
                                                let $connectionName := concat('Act ', $act, ', Scene ', $scene)
                                                let $connectionRow := for $row at $pos in $concRawData[tokenize(., ';')[position() = 1] = $act and tokenize(., ';')[position() = 2] = $scene][1]
                                                                        return
                                                                            $row
                                                let $connectionRowT := tokenize($connectionRow, ';')
                                                let $connectionParticipantNos := $connectionRowT[position() > 2 and position() < 7]
                                                let $plist := for $connectionParticipantNo at $pos in $connectionParticipantNos
                                                                    let $participantSource := $ediConcSourcesCollection[$pos]
                                                                    where $pos < 3 and normalize-space($connectionParticipantNo) != ''
                                                                    return
                                                                        (\:local:getConectionPlistParticipantString($participantSource, $mdiv, $connectionParticipantNo):\)
                                                                        let $participantSourceID := local:getParticipantSourceID($participantSource)
                                                                        return
                                                                            let $participantSourceMeasures2Connect := if ($participantSource/mei:mei/@xml:id = 'opera_source_6b03f75b-50eb-410b-b729-39c1725bc1cf')
                                                                                                                        then ($participantSource//mei:measure[@n = normalize-space($connectionParticipantNo)])
                                                                                                                        else if ($participantSource//tei:TEI/@xml:id = 'TextEdition')
                                                                                                                        then (
                                                                                                                            $participantSource//tei:l[number(@n) = number(functx:substring-before-if-contains($connectionParticipantNo, ','))]//ancestor::*/tei:head[@type = 'scene'] |
                                                                                                                            $participantSource//tei:lb[@type = 'lineNum'][number(@n) = number(functx:substring-before-if-contains($connectionParticipantNo, ','))]//ancestor::*/tei:head[@type = 'scene']
                                                                                                                            )
                                                                                                                        else ()
                                                                            return
                                                                                if (count($participantSourceMeasures2Connect) > 1)
                                                                                    then (concat(local:getConnectionPlistParticipantPrefix($participantSource), $participantSourceID, '.xml#', $participantSourceMeasures2Connect[1]/@xml:id/string(), '?tstamp2=', string(count($participantSourceMeasures2Connect) - 1), 'm+0 '))
                                                                                    else (concat(local:getConnectionPlistParticipantPrefix($participantSource), $participantSourceID, '.xml#', $participantSourceMeasures2Connect/@xml:id/string(), ' '))
                                                                                                     :\)               
                                                return
                                                    element connection {
                                                        attribute name {$connectionName},
                                                        attribute plist {$plist}
                                                        }
                                            }
                                        },
                                        element group {
                                            attribute name {'Text line'},
                                            element connections {
                                                let $connectionType := 'lines'
                                                let $concRawData := local:getConcRawData($ediConcType, $connectionType)
                                                let $ediConcSourcesCollection := local:getEdiConcSourcesCollectionFromCSVData($concRawData, $connectionType)
                                                
                                                for $row in $concRawData[position() > 1]
                                                    let $rowT := tokenize($row, ';')
                                                    let $mdiv := $rowT[position() = 3]
                                                    let $connectionNo := $rowT[position() = 4]
                                                    let $connectionParticipantNos := $rowT[position() > 4 and position() < 10]
                                                    let $plist := for $connectionParticipantNo at $pos in $connectionParticipantNos
                                                                    let $participantSource := $ediConcSourcesCollection[$pos]
                                                                    where $pos < 6 and normalize-space($connectionParticipantNo) != ''
                                                                    return
                                                                        local:getConectionPlistParticipantString($participantSource, $mdiv, $connectionParticipantNo, $connectionType)
                                                        return
                                                            element connection {
                                                                attribute name {$connectionNo},
                                                                attribute plist {$plist}
                                                                }
                                            }
                                        }
                                    }
                                }:)
                            }
                                        

return

(:    replace node $editionEdiromDoc//concordances with $concordancesCSVFile:)
(:$mdivsReference:)
(:$testOutput:)
$concordancesCSVFile
(:$ediConcSourcesCollection:)
