xquery version "3.1";

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

let $newFacsimile := <facsimile>{
                        for $surface in $sourceDoc//surface
                        let $surfaceID := $surface/@xml:id
                        let $surfaceN := $surface/@n
                        let $surfaceULX := $surface/@ulx
                        let $surfaceULY := $surface/@uly
                        let $surfaceLRX := $surface/@lrx
                        let $surfaceLRY := $surface/@lry
                        let $graphic := $surface/graphic
                        return
                            <surface xml:id="{$surfaceID}" n="{$surfaceN}" ulx="{$surfaceULX}" uly="{$surfaceULY}" lrx="{$surfaceLRX}" lry="{$surfaceLRY}">{
                            (
                            $graphic,
                            for $zone in $surface//zone[@type = 'measure']
                            let $dX := ($zone/@ulx + $zone/@lrx) idiv 2
                            let $dY := ($zone/@uly + $zone/@lry) idiv 2
                            let $dYtrim := substring(format-number($dY, '0000'), 1, 1)
                            let $ySquare := $dY * $dY
                            let $xSquare := $dX * $dX
                            let $c := round(math:sqrt($ySquare + $xSquare))
                            order by $dYtrim, $c
                            return
                                $zone
                            )
                            }
                            </surface>
                        }
                    </facsimile>

return
    replace node $sourceDoc//facsimile with $newFacsimile