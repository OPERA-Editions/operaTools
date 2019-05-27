xquery version "3.0";

declare default element namespace "http://www.music-encoding.org/ns/mei";

declare namespace imglist = "http://opera.uni-frankfurt.de/imglist";
declare namespace opera = "http://opera.uni-frankfurt.de/opera";
declare namespace uuid = "java:java.util.UUID";
import module namespace functx = "http://www.functx.com" at "../Resources/functx.xq";


declare option saxon:output "method=xml";
declare option saxon:output "media-type=text/xml";
declare option saxon:output "omit-xml-declaration=yes";
declare option saxon:output "indent=yes";
declare option saxon:output "saxon:indent-spaces=4";

let $editionContentsBasePathString := '../../'
let $editionID := 'edition-74338565'
let $editionsContentsBasePath := concat($editionContentsBasePathString, $editionID, '/')
let $sourceID := 'edirom_source_b469fc92-e13c-446f-873b-0208454ec03d'

let $sourceDoc := doc(concat($editionsContentsBasePath, 'sources/', $sourceID, '.xml'))

let $siglum := 'B'

let $imageList := functx:lines(unparsed-text(concat($editionsContentsBasePath, 'resources/', $siglum, '/', $siglum, '_dimensions.csv')))
let $imagesFakeCount := count($imageList)

let $surfaces := $sourceDoc//surface

for $surface at $pos in $surfaces
    
    let $newDataFromImageList := tokenize($imageList[$pos], ';')
    let $newResourceName := $newDataFromImageList[1]
    
    let $newDimensionX := number(substring-before($newDataFromImageList[2], 'x'))
    let $newDimensionY := number(substring-after($newDataFromImageList[2], 'x'))
    
    let $oldGraphic := $surface/graphic
    
    let $oldDimensionX := $oldGraphic/@width
    let $oldDimensionY := $oldGraphic/@height
    
    let $scaleFactorX := round-half-to-even($newDimensionX div $oldDimensionX, 1)
    let $scaleFactorY := round-half-to-even($newDimensionY div $oldDimensionY, 1)
    
    let $oldZones := $surface//zone
    
    let $newSurface := element surface {
                        attribute xml:id {$surface/@xml:id/string()},
                        attribute n {$surface/@n/string()},
                        
                        element graphic {
                            attribute xml:id {concat('opera_graphic_', uuid:randomUUID())},
                            attribute target {concat($editionID, '/', $sourceID, '/', $newResourceName)},
                            attribute type {'facsimile'},
                            attribute width {$newDimensionX},
                            attribute height {$newDimensionY}
                        },
                        
                        for $oldZone in $oldZones
                            let $zoneID := $oldZone/@xml:id
                            let $zoneType := $oldZone/@type
                            let $oldZoneUlx := $oldZone/@ulx
                            let $oldZoneUly := $oldZone/@uly
                            let $oldZoneLrx := $oldZone/@lrx
                            let $oldZoneLry := $oldZone/@lry
                            let $newZoneUlx := round($oldZoneUlx * $scaleFactorX)
                            let $newZoneUly := round($oldZoneUly * $scaleFactorY)
                            let $newZoneLrx := round($oldZoneLrx * $scaleFactorX)
                            let $newZoneLry := round($oldZoneLry * $scaleFactorX)
                            let $newZone := element zone {
                                                attribute xml:id {$zoneID},
                                                attribute type {$zoneType},
                                                attribute ulx {$newZoneUlx},
                                                attribute uly {$newZoneUly},
                                                attribute lrx {$newZoneLrx},
                                                attribute lry {$newZoneLry}
                                            }
                            return
                                $newZone
                    }
   
   return
    replace node $surface with $newSurface
(:$newSurface:)
   
   
    (:(
        replace node $oldGraphic with $newGraphic,
        delete nodes $oldZones,
        insert nodes $newZones into $surface
    ):)
