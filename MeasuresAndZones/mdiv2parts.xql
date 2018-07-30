xquery version "3.0";

declare namespace mei="http://www.music-encoding.org/ns/mei";

<body>

{let $sourceURI := 'xmldb:exist:///db/contents/edition-74338557/sources/opera_source_medea_A3.xml'
let $doc := doc($sourceURI)

for $mdiv at $pos in $doc//mei:mdiv

let $mdivID := $mdiv/@xml:id
let $mdivLabel := substring-before($mdiv/@label, ', ')

where $pos < 10
return
    
    <mdiv xml:id="{$mdivID}" label="{$mdivLabel}">
        <parts>
            {for $partMdiv in $doc//mei:mdiv
                let $partMdivLabel := $partMdiv/@label
                let $section := $partMdiv//mei:section
                let $partLabel := substring-after($partMdivLabel, ', ')
                let $partLabelID := $doc//mei:workDesc//mei:instrVoice[@label = $partLabel]/@xml:id
                where starts-with($partMdivLabel, $mdivLabel) 
                return
                <part xml:id="{concat('edirom_part_', util:uuid())}" label="{$partLabel}">
                    <staffDef decls="{concat('#', $partLabelID)}"/>
                    {$section}
                </part>
            }
        </parts>
    </mdiv>
}
</body>