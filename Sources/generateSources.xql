xquery version "3.0";

(:declare default element namespace "http://www.music-encoding.org/ns/mei";:)
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace imglist = "http://opera.uni-frankfurt.de/imglist";
declare namespace opera = "http://opera.uni-frankfurt.de/opera";
declare namespace uuid = "java:java.util.UUID";
import module namespace functx = "http://www.functx.com" at "../Resources/functx.xq";


(: Generate Source(s):
1.) Get file names and file dimensions in $imageList
2.) Get sources to generate from $sources 
3.) generate!

:)


let $editionContentsBasePathString := '../../'
let $editionID := 'edition-74338566'
let $editionsContentsBasePath := concat($editionContentsBasePathString, $editionID, '/')

let $sources := doc(concat($editionsContentsBasePath, 'resources/sources.xml'))//row

for $row in $sources

let $workID := normalize-space($row/workID)
let $workTitle := doc(concat($editionsContentsBasePath, 'works/', $workID, '.xml'))/mei:mei//mei:work/mei:titleStmt/mei:title/text()
let $workComposer := doc(concat($editionsContentsBasePath, 'works/', $workID, '.xml'))/mei:mei//mei:work//mei:titleStmt//*[@role = 'composer']/text()

let $siglum := normalize-space($row/Siglum)
let $imageList := functx:lines(unparsed-text(concat($editionsContentsBasePath, 'resources/', $siglum, '/', $siglum, '_dimensions.csv')))
let $imagesFakeCount := count($imageList) 

let $titleDE := normalize-space($row/TitleDE)
let $titleEN := normalize-space($row/TitleEN)

let $shelfmark := normalize-space($row/Signatur)
let $invNum := normalize-space($row/InvNum)

let $persons := $row//Person
let $composer := $row//Person[./Resp/text() = 'Composer']/RespName/text()
let $librettist := $row//Person[./Resp/text() = 'Librettist']/RespName/text()

let $type := normalize-space(lower-case($row/Type))
let $date := normalize-space($row/Date)

let $sourceUUID := concat('opera_source_', uuid:randomUUID())
let $mdivs := $row//mdiv

let $sourceFileName := concat($sourceUUID, '.xml')

let $content :=  <mei xmlns="http://www.music-encoding.org/ns/mei" xmlns:xlink="http://www.w3.org/1999/xlink" xml:id="{$sourceUUID}" meiversion="3.0.0">
                    <meiHead>
                        <fileDesc>
                            <titleStmt>{
                                if ($titleDE != '')
                                then (
                                    element title {
                                        attribute xml:lang {'de'},
                                        concat($workTitle, ' – ', $titleDE)
                                    },
                                    element title {
                                        attribute xml:lang {'de'},
                                        attribute type {'subtitle'},
                                        'Elektronische Transkription für das OPERA Projekt'
                                    }
                                )
                                else (
                                    element title {
                                        attribute xml:lang {'en'},
                                        concat($workTitle, ' – ', $titleEN)
                                    },
                                    element title {
                                        attribute xml:lang {'en'},
                                        attribute type {'subtitle'},
                                        'electronic transcription for the OPERA Project'
                                    }                                    
                                )
                            }
                            {
                                for $person in $persons
                                    let $resp := normalize-space(lower-case($person/Resp))
                                    let $name := normalize-space($person/RespName)
                                    return
                                        if ($composer != '')
                                        then (element composer {
                                                $composer
                                                }
                                        )
                                        else if ($librettist != '')
                                        then (element librettist {
                                                $librettist
                                                }
                                        )
                                        else ()
                            }
                                <respStmt>
                                    <resp>Encoded by the OPERA Project</resp>
                                    <encoder>Nikolaos Beer</encoder>
                                </respStmt>
                                <funder>Akademie der Wissenschaften und der Literatur, Mainz</funder>
                            </titleStmt>
                            <editionStmt>
                                <edition>OPERA – Spektrum des europäischen Musiktheaters in Einzeleditionen.</edition>
                            </editionStmt>
                            <pubStmt>unpublished</pubStmt>
                            <sourceDesc>
                                <source type="{$type}">
                                    <identifier type="siglum">{$siglum}</identifier>
                                    <!-- Die Signatur sollte später an die richtige Stelle in <physLoc> umziehen! -->
                                    <identifier type="shelfmark">{$shelfmark}</identifier>
                                    <titleStmt>
                                        <title xml:lang="de">{$titleDE}</title>
                                        <respStmt></respStmt>
                                    </titleStmt>
                                    <pubStmt>
                                        {if($date)
                                        then <date isodate="{$date}"></date>
                                        else()
                                        }
                                    </pubStmt>
                                    <relationList>
                                        <relation rel="isEmbodimentOf" target="{concat('xmldb:exist:///db/contents/', $editionID, '/works/', $workID, '.xml#', $workID, '_exp1')}"/>
                                    </relationList>
                                </source>
                            </sourceDesc>
                        </fileDesc>
                        <encodingDesc>
                            <projectDesc>
                                <p>{concat('Source transcribed by the OPERA Projekt for the Edition of ', if ($workComposer != '') then ($workComposer) else ($composer), '&apos;s &quot;', $workTitle, '&quot;.')}</p>
                            </projectDesc>
                        </encodingDesc>
                        <revisionDesc>
                            <change n="1" isodate="{current-date()}" resp="nbeer">
                                <p>File generated via script.</p>
                            </change>
                        </revisionDesc>
                    </meiHead>
                    <music>
                        <facsimile>
                           {
                                for $file at $pos in $imageList
                                    let $surfaceID := concat('opera_surface_', uuid:randomUUID())
                                    let $surfaceN := $pos
                                    let $fileName := substring-before($file, ';')
                                    let $graphicTarget := concat($editionID, '/', $sourceUUID, '/', $fileName)
                                    let $graphicWidth := normalize-space(substring-before(substring-after($file, ';'), 'x'))
                                    let $graphicHeight := normalize-space(substring-after(substring-after($file, ';'), 'x'))
                                    where $pos < $imagesFakeCount
                                    return
                                        <surface xml:id="{$surfaceID}" n="{$surfaceN}">
                                            <graphic target="{$graphicTarget}" type="facsimile" width="{$graphicWidth}" height="{$graphicHeight}"/>
                                        </surface>

                              }  
                        </facsimile>
                        <body>
                        {
                        for $mdiv in $mdivs
                        let $mdivID := concat('opera_mdiv_', uuid:randomUUID())
                        let $mdivLabel := $mdiv/text()
                        return
                            <mdiv xml:id="{$mdivID}" label="{$mdivLabel}">
                                <score>
                                    <scoreDef/>
                                    <section/>
                                </score>
                            </mdiv>
                        }
                        </body>
                    </music>
                  </mei>
return
$content
(:$imageList:)

