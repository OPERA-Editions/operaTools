xquery version "3.0";

(:~
: Adds @xml:id attribute and value to all occurances of elemet specified in $elementLocalName
: Nikolaos Beer, OPERA, 2018/19
:)

declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace functx="http://www.functx.com" at "../Resources/functx.xq";

declare option saxon:output "method=xml";
declare option saxon:output "media-type=text/xml";
declare option saxon:output "omit-xml-declaration=yes";
declare option saxon:output "indent=yes";


let $resourceName := 'LiaV_TE.xml'

let $elementLocalName := 'head'

(:  ID of Edirom edition file. :)
let $editionID := '74338558'

(: If there is a prefix ('edtion-' etc.) to the edition's ID, put it here! :)
let $editionIDPrefix := 'edition-'

let $basePathToEditionContents := '../../'

(:  Edition contents base path :)
let $pathToEditionContents := concat($basePathToEditionContents, $editionIDPrefix, $editionID, '/')

let $resource := doc(concat($pathToEditionContents, 'text/', $resourceName))

let $elements := $resource//*[local-name(.) = $elementLocalName][@type = 'air']

for $element in $elements
    let $conterString := $element/text()
    let $idString := concat(lower-case(tokenize($conterString, ' ')[1]), '-', format-number(number(tokenize($conterString, ' ')[2]), '00'))
    
    return
        insert node attribute xml:id {$idString} into $element