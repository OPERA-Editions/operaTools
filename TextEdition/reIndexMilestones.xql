xquery version "3.0";

(:~
: Reindexing milestones in OPERA Text Editions
: Nikolaos Beer, OPERA, 2018/19
:)

declare default element namespace "http://www.edirom.de/ns/1.3";

declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace functx="http://www.functx.com" at "../Resources/functx.xq";

declare option saxon:output "method=xml";
declare option saxon:output "media-type=text/xml";
declare option saxon:output "omit-xml-declaration=yes";
declare option saxon:output "indent=yes";

(:  ID of Edirom edition file. :)
let $editionID := 'edition-74338558'

(: Name of Text Edition file :)
let $textEditionFileNameString := 'LiaV_TE.xml'

(:  Base path string to the edition's contents :)
let $contentsBasePathString := '/Users/niko/Repos/OPERA-Edition/'

(:  Edition contents base path :)
let $contentsBasePath := concat($contentsBasePathString, $editionID, '/')

let $texEditionDoc := doc(concat($contentsBasePath, '/text/', $textEditionFileNameString))

let $milestonesAct := $texEditionDoc//tei:milestone[@unit = 'act']

for $milestoneAct at $i1 in $milestonesAct
    let $newActID := concat('milestone-', format-number($i1, '00'), '-00-00')
    let $milestonesScene := $milestoneAct/following-sibling::tei:div[1]//tei:milestone[@unit = 'scene']
    
return
    for $milestoneScene at $i2 in $milestonesScene
    let $newSceneID := concat('milestone-', format-number($i1, '00'), '-', format-number($i2, '00'), '-00')
    
    return
(:    $newSceneID:)
        replace value of node $milestoneScene/@xml:id with $newSceneID
        