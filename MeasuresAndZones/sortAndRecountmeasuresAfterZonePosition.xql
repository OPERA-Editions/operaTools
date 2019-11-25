xquery version "3.1";


(: ATTENTION: DO sortZonesbyXY.xql FIRST!!! :)

declare default element namespace "http://www.music-encoding.org/ns/mei";
(:declare namespace mei="http://www.music-encoding.org/ns/mei";:)
declare namespace opera = "http://opera.uni-frankfurt.de/opera";
declare namespace uuid = "java:java.util.UUID";
declare namespace math = "http://www.w3.org/2005/xpath-functions/math";
import module namespace functx = "http://www.functx.com" at "../Resources/functx.xq";

let $editionContentsBasePathString := '../../'
let $editionID := 'edition-74338558'
let $editionsContentsBasePath := concat($editionContentsBasePathString, $editionID, '/')

let $sourceID := 'opera_edition_3578ef42-491f-4bc1-a426-728553f3cdba'
let $sourceDoc := doc(concat($editionsContentsBasePath, 'sources/', $sourceID, '.xml'))

let $zones := $sourceDoc//zone

let $mdivs := $sourceDoc//mdiv

for $mdiv at $pos in $mdivs
    
    
    let $mdivID := $mdiv/@xml:id
    let $newMeasures := for $zone at $pos in $zones
                            let $zoneID := $zone/@xml:id
                            let $measureSearch := $sourceDoc//measure[contains(@facs, $zoneID)]
                            return
                                <measure xml:id="{$measureSearch/@xml:id}" n="{$pos}" facs="{$measureSearch/@facs}"/> 
    where $pos = 1                            
    return
        <mdiv xml:id="{$mdiv/@xml:id}" n="{$mdiv/@n}" label="{$mdiv/@label}">
            <scoreDef/>
            <section>
                {$newMeasures}
            </section>
        </mdiv>
                                

