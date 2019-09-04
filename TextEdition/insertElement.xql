xquery version "3.0";

(:~
: Insert $note element after $elementSearch in $resource
: Nikolaos Beer, OPERA, 2018/19
:)

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare namespace mei="http://www.music-encoding.org/ns/mei";
(:declare namespace tei="http://www.tei-c.org/ns/1.0";:)

import module namespace functx="http://www.functx.com" at "../Resources/functx.xq";

declare option saxon:output "method=xml";
declare option saxon:output "media-type=text/xml";
declare option saxon:output "omit-xml-declaration=yes";
declare option saxon:output "indent=yes";

let $resourceName := 'LiaV_TE.xml'

let $elementSearchLocalName := 'head'

(:  ID of Edirom edition file. :)
let $editionID := '74338558'

(: If there is a prefix ('edtion-' etc.) to the edition's ID, put it here! :)
let $editionIDPrefix := 'edition-'

let $basePathToEditionContents := '../../'

(:  Edition contents base path :)
let $pathToEditionContents := concat($basePathToEditionContents, $editionIDPrefix, $editionID, '/')

let $resource := doc(concat($pathToEditionContents, 'text/', $resourceName))

let $elements := $resource//*[local-name(.) = $elementSearchLocalName][@type = 'air']

for $element in $elements
    let $elementID := $element/@xml:id
    let $noteID := concat('opera_note_', $elementID, '_01')
    let $note := element note {
                    attribute xml:id {$noteID}
                    }
    return
        insert node $note after $element
