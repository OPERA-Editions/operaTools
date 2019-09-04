xquery version "3.0";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare option exist:serialize "method=xml media-type=text/xml omit-xml-declaration=yes indent=yes";

for $node at $pos in doc('xmldb:exist:///db/contents/edition-74338558/text/LiaV_TE.xml')//body//div[@type = 'act']//*[@xml:id]



let $n := fn:format-number($pos, '0000')

let $id := concat('opera_74338556_te_lb_', fn:format-number($pos, '0000'))

(:where $pos = 1:)
return
(:    $node:)
    update insert attribute n {$n} into $node
