xquery version "3.0";

declare default element namespace "http://www.music-encoding.org/ns/mei";
(:declare namespace mei="http://www.music-encoding.org/ns/mei";:)
declare namespace opera = "http://opera.uni-frankfurt.de/opera";
declare namespace uuid = "java:java.util.UUID";
import module namespace functx = "http://www.functx.com" at "../Resources/functx.xq";

let $mdivCount := 46

for $mdiv at $pos in 1 to $mdivCount
let $mdivID := concat('opera_mdiv_', uuid:randomUUID())
let $mdivLabel := $pos
return
    <mdiv xml:id="{$mdivID}" label="{$mdivLabel}">
        <score>
            <scoreDef/>
            <section/>
        </score>
    </mdiv>

