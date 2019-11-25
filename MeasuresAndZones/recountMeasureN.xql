xquery version "3.0";

declare default element namespace "http://www.music-encoding.org/ns/mei";
(:declare namespace mei="http://www.music-encoding.org/ns/mei";:)
declare namespace opera = "http://opera.uni-frankfurt.de/opera";
declare namespace uuid = "java:java.util.UUID";
import module namespace functx = "http://www.functx.com" at "../Resources/functx.xq";

let $editionContentsBasePathString := '../../'
let $editionID := 'edition-74338558'
let $editionsContentsBasePath := concat($editionContentsBasePathString, $editionID, '/')

let $sourceID := 'opera_edition_3578ef42-491f-4bc1-a426-728553f3cdba'
let $sourceDoc := doc(concat($editionsContentsBasePath, 'sources/', $sourceID, '.xml'))

return

