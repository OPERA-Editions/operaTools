xquery version "3.0";

declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace uuid = "java:java.util.UUID";

declare option saxon:output "method=xml";
declare option saxon:output "media-type=text/xml";
declare option saxon:output "omit-xml-declaration=yes";
declare option saxon:output "indent=yes";

(: This xquery takes the <body/> tag of a mei file which contains mdiv(s) for each combination of mdiv and instrument/voice and transforms its contents to "real" mdivs with the respective 
<parts><part/></parts> structure for each insturment/voice.

2018, Nikolaos Beer for the OPERA project in Frankfurt/Main, Germany. :)


(: Path to the mei file :)
let $editionID := ''
let $sourceID := ''
let $basePathToEditionContents := '../../'
let $sourceURI := concat($basePathToEditionContents, $editionID, '/sources/', $sourceID, '.xml')

let $doc := doc($sourceURI)

(:  1: mdiv-1 – part-1, mdiv-1 – part-2, mdiv-2 – part-1, mdiv-2 – part-2, etc.
    2: mdiv-1 – part-1, mdiv-2 – part-1, mdiv-1 – part-2, mdiv-2 – part-2, etc. :)
let $mdivPartOrder := '1'

(: Defines the divider string between mdiv title and instrument or voice name :)
let $mdivPartDivider := ' – '


(: ******* DO NOT CHANGE FROM HERE! ******* :)
return

    if ($mdivPartOrder = '1')
    then (
        <body>{
            let $realMdivsLabels :=  distinct-values($doc//mei:mdiv/@label/substring-before(., $mdivPartDivider))
            for $realMdivLabel in $realMdivsLabels
            return
                <mdiv xml:id="{concat('edirom_mdiv_', uuid:randomUUID())}" label="{$realMdivLabel}">
                    <parts>
                        {
                        for $partMdiv in $doc//mei:mdiv
                        let $partMdivLabel := $partMdiv/@label/string()
                        let $section := $partMdiv//mei:section
                        let $partLabel := substring-after($partMdivLabel, $mdivPartDivider)
                        let $partLabelID := $doc//mei:workDesc//mei:instrVoice[@label = $partLabel]/@xml:id
                        where starts-with($partMdivLabel, $realMdivLabel) 
                        return
                            <part xml:id="{concat('edirom_part_', uuid:randomUUID())}" label="{$partLabel}">
                                <staffDef decls="{concat('#', $partLabelID)}"/>
                                {$section}
                            </part>
                        }
                    </parts>
                </mdiv>
        }</body>
    )
    else if ($mdivPartOrder = '2')
    then (
        <body>{
            for $mdiv at $pos in $doc//mei:mdiv
            let $mdivID := $mdiv/@xml:id
            let $mdivLabel := substring-before($mdiv/@label, $mdivPartDivider)
            where $pos < 10
            return
                <mdiv xml:id="{$mdivID}" label="{$mdivLabel}">
                    <parts>{
                        for $partMdiv in $doc//mei:mdiv
                        let $partMdivLabel := $partMdiv/@label
                        let $section := $partMdiv//mei:section
                        let $partLabel := substring-after($partMdivLabel, $mdivPartDivider)
                        let $partLabelID := $doc//mei:workDesc//mei:instrVoice[@label = $partLabel]/@xml:id
                        where starts-with($partMdivLabel, $mdivLabel) 
                        return
                            <part xml:id="{concat('edirom_part_', uuid:randomUUID())}" label="{$partLabel}">
                                <staffDef decls="{concat('#', $partLabelID)}"/>
                                {$section}
                            </part>
                    }</parts>
                </mdiv>
        }</body>
    )
    else ()
