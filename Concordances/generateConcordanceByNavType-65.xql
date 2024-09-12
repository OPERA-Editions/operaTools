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
declare variable $editionID as xs:string := '74338565';

(:~ The prefix part ('edtion-' etc.) of the Edirom edition's @xml:id value :)
declare variable $editionIDPrefix as xs:string := 'edition-';

(:~ Resource fiel name of virtual concordance table (as CSV) (bars mode):)
(:declare variable $CSVResourceNameBars as xs:string := 'concordance_bars_rawData.csv';:)
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
declare variable $workID as xs:string := 'edirom_work_a2d35700-0012-413a-be06-77feea8aff60_exp1';

(:~ Work doc :)
declare variable $workDoc as document-node() := doc(concat($pathToEditionContents, 'works/', $workID, '.xml'));

(:~ @xml:id of the concordance reference source – mostly the edition's "source" :)
(: Vogelhändler: B :)
declare variable $referenceSourceID as xs:string := 'opera_source_bx69fc92-e13c-446f-873b-0208454ec0xb';

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
                                        then (functx:lines(unparsed-text(concat($pathToEditionContents, 'resources/concordance/', $CSVResourceNameBars))))
                                        else ();

(:~ Set raw concordance data for text line based concordance from CSV :)
declare variable $concRawDataLines := if ($ediConcType = 'fromCSV')
                                        then (functx:lines(unparsed-text(concat($pathToEditionContents, 'resources/concordance/', $CSVResourceNameLines))))
                                        else ();
                                        
(:~ Set raw concordance data for scenes based concordance from CSV :)
declare variable $concRawDataScenes := if ($ediConcType = 'fromCSV')
                                        then (functx:lines(unparsed-text(concat($pathToEditionContents, 'resources/concordance/', $CSVResourceNameScenes))))
                                        else ();

(:~ Specify your own source list here :)
declare variable $sourcesList := ();


declare variable $mdivsReference := if ($ediConcType = 'sourceList')
                                    then ($refSourceDoc//mei:mdiv)
                                    else if ($ediConcType = 'fromCSV')
                                    then (
                                        let $mdivs := for $row in $concRawDataBars[position() > 1]
(:                                        return $row:)
                                                        let $mdivLabel := tokenize($row, ';')[position() = 4]
(:                                                        return concat($mdivLabel, '|'):)
                                                        where $mdivLabel != ''
                                                        return
                                                            $mdivLabel
                                        return
                                            distinct-values($mdivs)
                                    )
                                    else('bla');
                        
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
        (collection(concat($pathToEditionContents, 'sources/?select=*.xml'))[.//mei:identifier[@type = 'siglum'] = $siglum] | collection(concat($pathToEditionContents, 'edition/?select=*.xml'))[.//tei:fileDesc//tei:title[@type = 'siglum'] = $siglum])
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
    (:if ($participantSource/tei:TEI)
    then (concat('xmldb:exist:///db/contents/', $editionIDPrefix, $editionID, '/texts/')):)
    if ($participantSource/tei:TEI or $participantSource/mei:mei/@xml:id = 'm-1')
    (:then (concat('xmldb:exist:///db/contents/', $editionIDPrefix, $editionID, '/edition/'))
    else (concat('xmldb:exist:///db/contents/', $editionIDPrefix, $editionID, '/sources/')):)
    then (concat('xmldb:exist:///db/apps/edirom/', $editionIDPrefix, $editionID, '/edition/'))
    else (concat('xmldb:exist:///db/apps/edirom/', $editionIDPrefix, $editionID, '/sources/'))
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
    then (tokenize($concRawData[1], ';')[position() > 2 and position() < 8])
    else (tokenize($concRawData[1], ';')[position() > 5 and position() < 15])
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
(:    concat(local:getParticipantSourceID($participantSource), '.xml#','measure_', $participantSource//mei:mdiv[@label = $mdiv]/@xml:id/string(), '_', $connectionParticipantNo, ''):)
    let $p := functx:substring-before-if-contains($connectionParticipantNo, ', ')
    let $begin := number(functx:substring-before-if-contains($p, '-'))
    let $end := number(functx:substring-after-if-contains($p, '-'))
    let $sequence :=
        if ($begin < $end)
        then(concat('?tstamp2=1m+', $end - $begin - 1))
        else()

    return
        concat(local:getParticipantSourceID($participantSource), '.xml#','measure_', $participantSource//mei:mdiv[@label = $mdiv]/@xml:id/string(), '_', $begin, $sequence)
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
(:    return $participantSource:)
(:    return concat($participantSource//mei:identifier[@type='siglum'] | $participantSource//tei:title[@type='siglum'], '|', $participantSourceID, '|', $connectionParticipantNo):)
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
                    (: text sources :)
                    (: Lindpainter: source_at1 : AT1 :)
                    if ($participantSource/mei:mei/@xml:id = 'source_at1')
                    then (
                        if (contains($connectionParticipantNo, ','))
                        then (
                            let $connectionParticipantNoT := tokenize($connectionParticipantNo, ', ')
                            return
                                for $p in $connectionParticipantNoT
                                return
                                    $participantSource//mei:measure[@n = normalize-space($p)]
(:                                    $participantSource//mei:measure[@n = concat('l. ', normalize-space(replace($p, '-', '–')))]:)
(:                                    $participantSource//mei:measure[@n = concat('', normalize-space(replace($p, '-', '–')))]:)

                        
                        )
                        (:else ($participantSource//mei:measure[@n = normalize-space(concat('l. ', $connectionParticipantNo))]):)
                        else ($participantSource//mei:measure[@n = normalize-space($connectionParticipantNo)])
(:                        else ($participantSource//mei:measure[@n = normalize-space(concat('l. ', replace($connectionParticipantNo, '-', '–')))])):)
(:                        else ($participantSource//mei:measure[@n = normalize-space(concat('', replace($connectionParticipantNo, '-', '–')))])):)
                    )
                    
                    
                    
                    
                    (: music sources :)
                    (: Lindpaintner: edirom_source_b469fc92-e13c-446f-873b-0208454ec03d: B; opera_source_ea728ec0-2219-440b-9aed-273844486cc0: C; opera_source_d04ffca4-abe9-4320-b096-80bae356b8d0: D :)
                    else if (($participantSource/mei:mei/@xml:id = 'source_a1' or $participantSource/mei:mei/@xml:id = 'source_a2' or $participantSource/mei:mei/@xml:id = 'source_a3' or $participantSource/mei:mei/@xml:id = 'source_a4' or $participantSource/mei:mei/@xml:id = 'source_b' or $participantSource/mei:mei/@xml:id = 'source_c') )
                    (: and contains($connectionParticipantNo, ',') :)
                    then (
                        let $p := functx:substring-before-if-contains($connectionParticipantNo, ', ')
                        let $begin := number(functx:substring-before-if-contains($p, '-'))
                        let $end := number(functx:substring-after-if-contains($p, '-'))
                        return
                            subsequence($participantSource//mei:measure[.//ancestor::mei:mdiv[@label = $mdiv]][number(@n) >= $begin and number(@n) <= $end](:[$end - $begin + 1]:), 1, $end - $begin + 1)

                        (: that would be the best way but concordance cannot show more than one group of measures. and it does not work correctly if there are more then one occurences of @n in the same <mdiv> :)
(:                        let $connectionParticipantNoT := tokenize($connectionParticipantNo, ', ')
                            return
                                for $p in $connectionParticipantNoT
                                return
                                    $participantSource//mei:measure[.//ancestor::mei:mdiv[@label = $mdiv]][number(@n) >= number(functx:substring-before-if-contains($p, '-')) and number(@n) <= number(functx:substring-after-if-contains($p, '-'))]:)
                    
                    
                    
                    
(:                        if (contains(substring-before($connectionParticipantNo, ','), '-'))
                        then (
                            $participantSource//mei:measure[.//ancestor::mei:mdiv[@label = $mdiv]][number(@n) >= number(substring-before($connectionParticipantNo, '-')) and number(@n) <= number(substring-before(substring-after($connectionParticipantNo, '-'), ','))]
                        )
                        else(
(\:                            $participantSource//mei:measure[.//ancestor::mei:mdiv[@label = $mdiv]][@n = normalize-space(substring-before($connectionParticipantNo, ','))]:\)
                            let $connectionParticipantNoT := tokenize($connectionParticipantNo, ', ')
                            return
                                for $p in $connectionParticipantNoT
                                return
(\:                                    $participantSource//mei:measure[@n = normalize-space($p)]:\)
                                    $participantSource//mei:measure[.//ancestor::mei:mdiv[@label = $mdiv]][@n = normalize-space($p)]
                        ):)
                    )
                    
                    
                    
                    
(:                    then (
                        if (contains(substring-before($connectionParticipantNo, ','), '-'))
                        then (
                            $participantSource//mei:measure[.//ancestor::mei:mdiv[@label = $mdiv]][number(@n) >= number(substring-before($connectionParticipantNo, '-')) and number(@n) <= number(substring-before(substring-after($connectionParticipantNo, '-'), ','))]
                        )
                        else(
(\:                            $participantSource//mei:measure[.//ancestor::mei:mdiv[@label = $mdiv]][@n = normalize-space(substring-before($connectionParticipantNo, ','))]:\)
                            let $connectionParticipantNoT := tokenize($connectionParticipantNo, ', ')
                            return
                                for $p in $connectionParticipantNoT
                                return
(\:                                    $participantSource//mei:measure[@n = normalize-space($p)]:\)
                                    $participantSource//mei:measure[.//ancestor::mei:mdiv[@label = $mdiv]][@n = normalize-space($p)]
                        )
                    ):)
                    
                    
                    
                    (: Lindpaintner: edirom_source_b469fc92-e13c-446f-873b-0208454ec03d: B; opera_source_ea728ec0-2219-440b-9aed-273844486cc0: C; opera_source_d04ffca4-abe9-4320-b096-80bae356b8d0: D :)
                    else if (($participantSource/mei:mei/@xml:id = 'edirom_source_b469fc92-e13c-446f-873b-0208454ec03d' or $participantSource/mei:mei/@xml:id = 'opera_source_ea728ec0-2219-440b-9aed-273844486cc0' or $participantSource/mei:mei/@xml:id = 'opera_source_d04ffca4-abe9-4320-b096-80bae356b8d0') and contains($connectionParticipantNo, '+'))
                    then (
(:                        $connectionParticipantNo:)
                        $participantSource//mei:measure[.//ancestor::mei:mdiv[@label = $mdiv]][number(@n) = number(substring-before($connectionParticipantNo, '+')) or number(@n) <= number(substring-after($connectionParticipantNo, '+'))]
(:                        $participantSource//mei:measure[.//ancestor::mei:mdiv[@label = $mdiv]][number(@n) = number(substring-before($connectionParticipantNo, '-')) and number(@n) <= number(substring-after($connectionParticipantNo, '-'))]:)
                    )
                    
                    
                    
                    
                    
                    
                    
                    
                    (: text edition :)
                    else if ($participantSource//tei:TEI/@xml:id = 'TextEdition')
                    then ($participantSource//tei:l[number(@n) = number(functx:substring-before-if-contains($connectionParticipantNo, ','))] | $participantSource//tei:seg[number(@n) = number(functx:substring-before-if-contains($connectionParticipantNo, ','))] | $participantSource//tei:lb[@type = 'lineNum'][number(@n) = number(functx:substring-before-if-contains($connectionParticipantNo, ','))])
(:                    then ($participantSource//tei:l[@xml:id = 'line-322']):)
                    
                    
                    
                    (: default: music source? :)
                    else ($participantSource//mei:measure[.//ancestor::mei:mdiv[@label = $mdiv]][@n = normalize-space($connectionParticipantNo)])
(:                    else():)
(:                    else ($mdiv):)
(:                    else ($connectionParticipantNo):)
(:            return $participantSourceMeasures2Connect:)

            let $filename :=  if ($participantSourceID = 'TextEdition')
                              then ('edition_text')
                              else if (contains($participantSourceID, 'source'))
                              then (concat('source_', lower-case($participantSource//mei:identifier[@type = 'siglum'])))
                              else ($participantSourceID)
            return
            
                if (count($participantSourceMeasures2Connect) > 1)
(:                then (concat(local:getConnectionPlistParticipantPrefix($participantSource), $participantSourceID, '.xml#', $participantSourceMeasures2Connect[1]/@xml:id/string(), '?tstamp2=', string(count($participantSourceMeasures2Connect) - 1), 'm+0 '))
:)                then (concat(local:getConnectionPlistParticipantPrefix($participantSource), $filename, '.xml#', $participantSourceMeasures2Connect[1]/@xml:id/string(), '?tstamp2=', string(count($participantSourceMeasures2Connect) - 1), 'm+0 '))
                else if (count($participantSourceMeasures2Connect) = 1)
(:                then (concat(local:getConnectionPlistParticipantPrefix($participantSource), $participantSourceID, '.xml#', $participantSourceMeasures2Connect/@xml:id/string(), ' ')):)
                then (concat(local:getConnectionPlistParticipantPrefix($participantSource), $filename, '.xml#', $participantSourceMeasures2Connect/@xml:id/string(), ' '))
                else ()
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
    let $act := local:roman2arabic(substring-after(substring-before($connectionParticipantName, ','), 'Act '))
    let $scene := local:roman2arabic(substring-after($connectionParticipantName, 'Scene '))
    
    return
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
        if (count($participantSourceMeasures2Connect) > 1)
                then (concat(local:getConnectionPlistParticipantPrefix($participantSource), $participantSourceID, '.xml#', $participantSourceMeasures2Connect[1]/@xml:id/string(), '?tstamp2=', string(count($participantSourceMeasures2Connect) - 1), 'm+0 '))
                else if (count($participantSourceMeasures2Connect) = 1)
                then (concat(local:getConnectionPlistParticipantPrefix($participantSource), $participantSourceID, '.xml#', $participantSourceMeasures2Connect/@xml:id/string(), ' '))
                else ()
                

};


let $testOutput := 
                                        let $connectionType := 'bars'
                                        let $concRawData := local:getConcRawData($ediConcType, $connectionType)
                                        let $ediConcSourcesCollection := local:getEdiConcSourcesCollectionFromCSVData($concRawData, $connectionType)
                                        (: sigla :)
                                        let $test := local:getSourceSiglaFromCSV($concRawData, $connectionType)
(:    return $ediConcSourcesCollection:)
(:    return $ediConcSourcesCollection:)
return $test

let $concordancesCSVFile := element concordances {

                                (: navigation by number & bar :)
                                element concordance {
                                    (:attribute name {'Navigation by number &amp; bar'},:)
                                    element names {
                                        element name {
                                            attribute xml:lang {'en'},
                                            'Navigation by number &amp; bar'
                                        }
                                    },
                                    element groups {
                                        element names {
                                            element name {
                                                attribute xml:lang {'en'}
                                            }
                                        },
                                        let $connectionType := 'bars'
                                        let $concRawData := local:getConcRawData($ediConcType, $connectionType)
                                        let $ediConcSourcesCollection := local:getEdiConcSourcesCollectionFromCSVData($concRawData, $connectionType)
                                        for $mdiv in $mdivsReference
                                        return
                                            element group {
                                                (:attribute name {$mdiv},:)
                                                element names {
                                                    element name {
                                                        attribute xml:lang {'en'},
                                                        $mdiv
                                                    }
                                                },
                                                
                                                
                                                element connections {
                                                    (:attribute label {'Bar'},:)
                                                    element names {
                                                        element name {
                                                            attribute xml:lang {'en'},
                                                            'Bar'
                                                        }
                                                    },
(:                                                    attribute row {$concRawData[position() =2][tokenize(., ',')[position() = 4] ]}:)
(:                                                    for $row in $concRawData[position() > 1][tokenize(., ',')[position() = 4] = $mdiv]:)
                                                    for $row in $concRawData[position() > 1][tokenize(., ';')[position() = 4] = $mdiv]
(:                                                        return $row:)
                                                        let $rowT := tokenize($row, ';')
                                                        
                                                        let $connectionNo := $rowT[position() = 5]
                                                        let $connectionParticipantNos := $rowT[position() > 5 and position() < 15]
(:                                                        return $connectionParticipantNos:)
                                                        
                                                        (: Lindpaitner:  6(1) = ME | 7(2) = A1 | 8(3) = A2 | 9(4) = A3 | 10(5) = A4 | 11(6) = B | 12(7) = C | 13(8) = AT1 :)
                                                        let $plist :=   for $connectionParticipantNo at $pos in $connectionParticipantNos
(:                                                        return $connectionParticipantNo:)
(:                                                            return $pos:)
(:                                                            return $ediConcSourcesCollection:)
                                                                        let $participantSource := $ediConcSourcesCollection[$pos]
                                                                        where $pos < 10 and normalize-space($connectionParticipantNo) != ''
                                                                        return 
                                                                            local:getConectionPlistParticipantString($participantSource, $mdiv, $connectionParticipantNo, $connectionType)
(:                                                                            $connectionParticipantNo:)
(:                                                        return $plist:)
                                                        return
                                                            element connection {
(:                                                                attribute sourcecollectioncount {count($ediConcSourcesCollection)},:)
(:                                                                attribute row {$row},:)
(:                                                                attribute cPN { fn:string-join($connectionParticipantNos, ',') },:)
(:                                                                attribute mdiv { $mdiv },:)
                                                                attribute name {$connectionNo},
                                                                attribute plist {$plist}
                                                            }
                                                }
                                            }
                                    }
                                    
                                        
                                } (:,
                                
                                element concordance {
                                    (\:attribute name {'Navigation by text line'},:\)
                                    element names {
                                        element name {
                                            attribute xml:lang {'en'},
                                            'Navigation by text line'
                                        }
                                    },
                                    element groups {
                                        element names {
                                            element name {
                                                attribute xml:lang {'en'}
                                            }
                                        },
                                        (\: navigation by scene :\)
                                        (\:element group {
                                            (\:attribute name {'Scene'},:\)
                                            element names {
                                                element name {
                                                    attribute xml:lang {'en'},
                                                    'Scene'
                                                }
                                            },
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
                                        },:\)
                                        
                                        (\: navigation by text line :\)
                                        element group {
                                            (\:attribute name {'Text line'},:\)
                                            element names {
                                                element name {
                                                    attribute xml:lang {'en'},
                                                    'Text line'
                                                }
                                            },
                                            element connections {
                                                element names {
                                                    element name {
                                                        attribute xml:lang {'en'},
                                                        'Line'
                                                    }
                                                },
                                                let $connectionType := 'lines'
                                                let $concRawData := local:getConcRawData($ediConcType, $connectionType)
                                                let $ediConcSourcesCollection := local:getEdiConcSourcesCollectionFromCSVData($concRawData, $connectionType)
                                                
                                                for $row in $concRawData[position() > 1]
                                                    let $rowT := tokenize($row, ';')
                                                    let $mdiv := $rowT[position() = 4]
                                                    let $connectionNo := $rowT[position() = 5]
                                                    let $connectionParticipantNos := $rowT[position() > 5 and position() < 15]
                                                    let $plist := for $connectionParticipantNo at $pos in $connectionParticipantNos
                                                                    let $participantSource := $ediConcSourcesCollection[$pos]
                                                                    where $pos < 10 and normalize-space($connectionParticipantNo) != ''
                                                                    return
                                                                        local:getConectionPlistParticipantString($participantSource, $mdiv, $connectionParticipantNo, $connectionType)
                                                        return
                                                            element connection {
(\:                                                                attribute mdiv {$mdiv},:\)
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
