xquery version "3.0";

declare default element namespace "http://www.music-encoding.org/ns/mei";
(:declare namespace mei="http://www.music-encoding.org/ns/mei";:)
declare namespace opera = "http://opera.uni-frankfurt.de/opera";
declare namespace uuid = "java:java.util.UUID";
import module namespace functx = "http://www.functx.com" at "../Resources/functx.xq";

<meiCorpus>
{
let $editionContentsBasePathString := '../../'
let $editionID := 'edition-74338558'
let $editionsContentsBasePath := concat($editionContentsBasePathString, $editionID, '/')

let $workID := 'opera_work_d471efd4-7c6f-4e07-9195-8a6fd713f227'
let $workTitle := doc(concat($editionsContentsBasePath, 'works/', $workID, '.xml'))/mei//work/titleStmt/title/text()
let $workComposer := doc(concat($editionsContentsBasePath, 'works/', $workID, '.xml'))/mei//work//titleStmt//*[@role = 'composer']/text()

let $imageListRAW := functx:lines(unparsed-text(concat($editionsContentsBasePath, 'resources/Images_Borrowings.csv')))
let $imageList := for $i in $imageListRAW
                    where starts-with($i, './No')
                    return
                        $i
                        
(: Filter references to images which belong to 'No X' images :)
let $borrowings := for $image in $imageList
                    let $borrowing := substring-after(substring-before($image, '_'), './')
                    return
                        $borrowing

(: Get disitnct values of No values and loop :)
for $borrowing at $pos in distinct-values($borrowings)
    
    (: Get all images for this specific borrowing/number   :)
    let $localImageList := for $image in $imageList
                            where contains($image, $borrowing)
                            return
                                $image
    
    let $title := $borrowing
    
    let $no := format-number(number(substring($borrowing, 3, 2)), '##')
    
    (: Filter all figures for one borrowing :)
    let $figures := for $item in $localImageList
                        let $figure := substring-before(substring-after($item, '_'), '/')
                        return
                            $figure
    
    order by $borrowing
    
    return
        
        (: Get disitnct values of figure(s) for this borrowing/number :)
        for $figure in distinct-values($figures)
        
        (: Filter all images for one figure of this borrowing :)
        let $figureImagesList := for $image in $localImageList
                                    where contains($image, $borrowing) and contains($image, $figure)
                                    order by $image
                                    return
                                        $image
                                        
        
    
        let $sourceID := concat('opera_comment_',$borrowing, '_', $figure)
        
        let $figNo := substring($figure, 4, 1)
        
        let $figTitle := concat('No. ', $no,', Fig. ', $figNo, ' — ')
    
        let $content :=  <mei xml:id="{$sourceID}" meiversion="3.0.0">
                            <meiHead>
                                <fileDesc>
                                    <titleStmt>
                                    <title>{$figTitle}</title>
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
                                        <source>
                                            <titleStmt>
                                                <title>{$figTitle}</title>
                                                <identifier/>
                                            </titleStmt>
                                            <pubStmt/>
                                            <relationList>
                                                <relation rel="isEmbodimentOf" target="{concat('xmldb:exist:///db/contents/', $editionID, '/works/', $workID, '.xml#', $workID, '_exp1')}"/>
                                            </relationList>
                                        </source>
                                    </sourceDesc>
                                </fileDesc>
                                <encodingDesc>
                                    <projectDesc>
                                        <p>{concat('Source transcribed by the OPERA Projekt for the Edition of ', $workComposer, '&apos;s &quot;', $workTitle, '&quot;.')}</p>
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
                                        for $file at $pos in $figureImagesList
                                            let $surfaceID := concat('opera_surface_', uuid:randomUUID())
                                            let $surfaceN := $pos
                                            let $fileName := substring-after(substring-before($file, ';'), './')
                                            let $graphicTarget := concat($editionID, '/graphics/', $fileName)
                                            let $graphicWidth := normalize-space(substring-before(substring-after($file, ';'), 'x'))
                                            let $graphicHeight := normalize-space(substring-after(substring-after($file, ';'), 'x'))
                                            return
                                                <surface xml:id="{$surfaceID}" n="{$surfaceN}">
                                                    <graphic target="{$graphicTarget}" type="facsimile" width="{$graphicWidth}" height="{$graphicHeight}"/>
                                                </surface>
        
                                      }  
                                </facsimile>
                            </music>
                        </mei>


(:where $pos = 1:)
                order by $figure
                return
                    $content
    }
    </meiCorpus>
(:$imageList:)

(:xmldb:store('xmldb:exist:///db/contents/edition-74338564/sources/', $sourceFileName, $content):)