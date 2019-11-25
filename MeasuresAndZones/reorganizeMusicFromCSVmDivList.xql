xquery version "3.1";

declare default element namespace "http://www.music-encoding.org/ns/mei";
(:declare namespace mei="http://www.music-encoding.org/ns/mei";:)
declare namespace opera = "http://opera.uni-frankfurt.de/opera";
declare namespace uuid = "java:java.util.UUID";
declare namespace math = "http://www.w3.org/2005/xpath-functions/math";
import module namespace functx = "http://www.functx.com" at "../Resources/functx.xq";

<body>{

let $editionContentsBasePathString := '../../'
let $editionID := 'edition-74338558'
let $editionsContentsBasePath := concat($editionContentsBasePathString, $editionID, '/')

let $sourceID := 'opera_edition_3578ef42-491f-4bc1-a426-728553f3cdba'
let $sourceDoc := doc(concat($editionsContentsBasePath, 'sources/', $sourceID, '.xml'))

let $csv := functx:lines(unparsed-text(concat($editionsContentsBasePath, 'resources/me_measuresPerMdiv.csv')))
let $csv := for $i at $pos in $csv
                where $pos > 1
                return $i
                
let $musicMeasuresMaxCount := sum(for $i in $csv
                                    return number(tokenize($i, ';')[2]))
                                    
let $measures := $sourceDoc//measure

for $line at $pos in $csv
    let $lineT := tokenize($line, ';')
    let $mdivLabel := if (number($lineT[1]))
                        then (concat('Air ', string($lineT[1])))
                        else (string($lineT[1]))
    let $mdivMeasuresMaxCount := number($lineT[2])
    let $mdivMeasureElementsMaxCount := number($lineT[3])
    let $mdivMeasureFirstNumber := number($lineT[4])
    let $mdivMeasureNumbersWith2Zones := if ($lineT[5] != '')
                                            then (tokenize($lineT[5], ', '))
                                            else ()
                                            
    let $mdivID := concat('opera_mdiv_', uuid:randomUUID())
                                            
    let $newMdiv :=    <mdiv xml:id="{$mdivID}" n="{$pos}" label="{$mdivLabel}" >
                        <scoreDef/>
                        <section>{
                            let $countPreviousMeasuresCount :=  if ($pos > 1)
                                                                then (
                                                                    sum(
                                                                        for $l in $csv[position() < $pos]
                                                                        return
                                                                            number(tokenize($l, ';')[3])
                                                                    )
                                                                )
                                                                else (0)
                            let $mdivMeasurePosStart := $countPreviousMeasuresCount + 1
                            let $mdivMeasurePosEnd := $mdivMeasurePosStart + $mdivMeasureElementsMaxCount - 1
                            
                            
                            
                            
                            for $measure at $m in $measures[position() >= $mdivMeasurePosStart and position() <= $mdivMeasurePosEnd]
                                let $measureID := $measure/@xml:id
                                let $measureN := $measure/@n
                                let $measureFacs := $measure/@facs
                                
                                let $measureCounter := if ($mdivMeasureFirstNumber = 0)
                                                        then ($m - 1)
                                                        else ($m)
                                
                                (: hängt ab von $m und ob $m in $mdivMeasureNumbersWith2Zones enthalten ist und welche Indexposition $m in $mdivMeasureNumbersWith2Zones hat :)
                                let $measureLabelModifier :=    if (count($mdivMeasureNumbersWith2Zones) = 1)
                                                                then (
                                                                    if (number($measureCounter) > number($mdivMeasureNumbersWith2Zones))
                                                                    then (1)
                                                                    else (0)
                                                                )
                                                                else if (count($mdivMeasureNumbersWith2Zones) > 1)
                                                                then (
                                                                    if (number($measureCounter) <= number($mdivMeasureNumbersWith2Zones[1]))
                                                                    then (0)
                                                                    else (
                                                                        for $l at $p in $mdivMeasureNumbersWith2Zones
                                                                        let $l := if ($p > 1)
                                                                                    then (number($l) + $p)
                                                                                    else (number($l))
                                                                        let $next := if ($mdivMeasureNumbersWith2Zones[$p + 1])
                                                                                        then (
                                                                                            if ($p >= 1)
                                                                                            then (number($mdivMeasureNumbersWith2Zones[$p + 1]) + $p)
                                                                                            else (number($mdivMeasureNumbersWith2Zones[$p + 1]))
                                                                                            )
                                                                                        else ()
                                                                        where if ($next) then (number($measureCounter) > number($l) and number($measureCounter) <= number($next)) else (number($measureCounter) > number($l))            
                                                                        return
                                                                        (:concat($p, ' ', $l, ' ', $measureCounter , ' ', $next):)
                                                                        $p
                                                                    )
                                                                )
                                                                else (0)
                                
                                let $measureLabel := string($measureCounter - $measureLabelModifier)
                            return
                                <measure xml:id="{$measureID}" n="{$measureLabel}" facs="{$measureFacs}" label="{$measureLabel}"/>
                        }</section>
                    </mdiv>
    
return
$newMdiv
}</body>