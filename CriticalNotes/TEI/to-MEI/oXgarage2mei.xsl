<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:mei="http://www.music-encoding.org/ns/mei"
  xmlns:edi="http://www.edirom.de/ns/1.3"
  xmlns:uuid="java:java.util.UUID"
  xmlns:functx="http://www.functx.com"
  xmlns="http://www.music-encoding.org/ns/mei"
  exclude-result-prefixes="xs xd"
  version="3.0">
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Created on:</xd:b> Nov 14, 2017</xd:p>
      <xd:p><xd:b>Author:</xd:b> bwb</xd:p>
      <xd:p>Postprocessing needed: check for mei:rend with trailing whitespace that should come after the closing tag</xd:p>
      <xd:p><xd:b>Modified on:</xd:b> Mar 7, 2018</xd:p>
      <xd:p><xd:b>Author:</xd:b> nbeer</xd:p>
      <xd:p>Layout of CR titles; first attempts for concordanz check.</xd:p>
    </xd:desc>
  </xd:doc>
  
  <xsl:output indent="yes" omit-xml-declaration="yes"></xsl:output>
  
  <xd:doc>
    <xd:desc/>
    <xd:param name="arg"/>
  </xd:doc>
  <xsl:function name="functx:escape-for-regex" as="xs:string"
   >
    <xsl:param name="arg" as="xs:string?"/>
    
    <xsl:sequence select="
      replace($arg,
      '(\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))','\\$1')
      "/>
    
  </xsl:function>
  
  <xd:doc>
    <xd:desc/>
    <xd:param name="arg"/>
    <xd:param name="delim"/>
  </xd:doc>
  <xsl:function name="functx:substring-after-last" as="xs:string"
   >
    <xsl:param name="arg" as="xs:string?"/>
    <xsl:param name="delim" as="xs:string"/>
    
    <xsl:sequence select="
      replace ($arg,concat('^.*',functx:escape-for-regex($delim)),'')
      "/>
    
  </xsl:function>
  
  <xd:doc>
    <xd:desc/>
    <xd:param name="arg"/>
    <xd:param name="delim"/>
  </xd:doc>
  <xsl:function name="functx:substring-before-last" as="xs:string"
   >
    <xsl:param name="arg" as="xs:string?"/>
    <xsl:param name="delim" as="xs:string"/>
    
    <xsl:sequence select="
      if (matches($arg, functx:escape-for-regex($delim)))
      then replace($arg,
      concat('^(.*)', functx:escape-for-regex($delim),'.*'),
      '$1')
      else ''
      "/>
    
  </xsl:function>
    
  <!-- ID of MEI work file. -->
  <xsl:variable name="workID" as="xs:string">opera_work_4fb7f9fb-12b0-4266-8da3-3c4420c2a714</xsl:variable>
  
  <!-- ID of EDIROM edition file. -->
  <xsl:variable name="editionID" as="xs:string">74338557</xsl:variable>
  
  <!-- If there is a prefix ('edtion-' etc.) to the edition's ID, put it here! -->
  <xsl:variable name="editionIDPrefix" as="xs:string">edition-</xsl:variable>
  
  <!-- Choose your annotation ID's prefix -->
  <xsl:variable name="annotIDPrefix" as="xs:string">opera_annot_</xsl:variable>
  
  <!-- The relative path to the edition's root content folder, seen from this xslt's folder. -->
  <xsl:variable name="basePathToEditionContents" as="xs:string">../../../../</xsl:variable>
  
  
  <!-- ********************************************************************* -->
  <!-- ********************************************************************* -->
  <!-- ** Do not change from here, otherwise you know what you are doing! ** -->
  <!-- ********************************************************************* -->
  <!-- ********************************************************************* -->

  <xsl:variable name="pathToEditionContents" as="xs:string">
    <xsl:value-of select="concat($basePathToEditionContents, $editionIDPrefix, $editionID)"/>
  </xsl:variable>
  <xsl:variable name="sourceDocs" select="collection(concat($pathToEditionContents, '/sources?select=*.xml'))" as="document-node()*"/>
  <xsl:variable name="editionDoc" select="doc(concat($pathToEditionContents, '/', $editionIDPrefix, $editionID, '.xml'))" as="document-node()"/>
<!--  <xsl:variable name="editionConcordances" select="$editionDoc//edi:work[@xml:id = $workID]//edi:concordances//edi:concordance"/>-->
  <xsl:variable name="editionConcordances" select="$editionDoc//edi:work[@xml:id = $workID]//edi:concordances//edi:concordance[1]" as="node()*"/>
  
  
  <xd:doc>
    <xd:desc/>
  </xd:doc>
  <xsl:template match="text()">
    <xsl:analyze-string select="." regex="JS\d{{4}}-\d{{2}}-\d{{2}}T\d{{2}}:\d{{2}}:\d{{2}} \[\[\[.*?\]\]\]">
      <xsl:matching-substring/>
      <xsl:non-matching-substring>
        <xsl:analyze-string select="." regex=" +">
          <xsl:matching-substring>
            <xsl:text> </xsl:text>
          </xsl:matching-substring>
          <xsl:non-matching-substring>
            <xsl:value-of select="normalize-space(.)"/>
          </xsl:non-matching-substring>
        </xsl:analyze-string>
      </xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:template>
  
  <xd:doc>
    <xd:desc/>
  </xd:doc>
  <xsl:template match="/">
    <xsl:element name="annot">
      <xsl:attribute name="type">criticalCommentary</xsl:attribute>
      
      <xsl:for-each select="(//tei:table[@xml:id='Table1']/tei:row)[position() > 1]"><!-- position()>1 | 56-->
        <xsl:variable name="no" select="tei:cell[1]" as="xs:string"/>
        
        <!-- Taktangaben -->
        <xsl:variable name="bar_first" select="normalize-space(tei:cell[2])" as="xs:string"/>
        <xsl:variable name="bar_last" select="normalize-space(tei:cell[3])" as="xs:string"/>
        
        <!-- Szene -->
        <xsl:variable name="table.scene" select="normalize-space(tei:cell[4])" as="xs:string"/>
        
        <!-- Segmentangaben -->
        <xsl:variable name="seg_first" select="normalize-space(tei:cell[5])" as="xs:string"/>
        <xsl:variable name="seg_last" select="normalize-space(tei:cell[6])" as="xs:string"/>
        
        <!-- Spottitel -->
        <xsl:variable name="spotTitle" select="normalize-space(tei:cell[7])" as="xs:string"/>
        
        <!-- Stimmen -->
        <xsl:variable name="system" select="normalize-space(tei:cell[8])" as="xs:string"/>
        <xsl:variable name="systemT" select="tokenize($system, ', ')"/>
        <xsl:variable name="parts" as="item()*">
          <xsl:for-each select="$systemT">
            <xsl:choose>
              <xsl:when test=". = 'all parts'">
                <xsl:value-of select="'all'"/>
              </xsl:when>
              <xsl:when test=". = 'Vl. solo'">
                <xsl:value-of select="'Violino principale'"/>
              </xsl:when>
              <xsl:when test=". = 'Vl. I'">
                <xsl:value-of select="'Violino primo'"/>
              </xsl:when>
              <xsl:when test=". = 'Vl. II'">
                <xsl:value-of select="'Violino secondo'"/>
              </xsl:when>
              <xsl:when test=". = 'Va. I'">
                <xsl:value-of select="'Viola'"/>
              </xsl:when>
              <xsl:when test=". = 'Va. II'">
                <xsl:value-of select="'Viola'"/>
              </xsl:when>
              <xsl:when test=". = 'Va. I/II'">
                <xsl:value-of select="'Viola'"/>
              </xsl:when>
              <xsl:when test=". = 'Bassi'">
                <xsl:value-of select="'Violoncello e Contraviolone'"/>
              </xsl:when>
              <xsl:when test=". = 'Vc.'">
                <xsl:value-of select="'Violoncello e Contraviolone'"/>
              </xsl:when>
              <xsl:when test=". = 'Fl. I'">
                <xsl:value-of select="'Flauto primo'"/>
              </xsl:when>
              <xsl:when test=". = 'Fl. II'">
                <xsl:value-of select="'Flauto secondo'"/>
              </xsl:when>
              <xsl:when test=". = 'Ob. I'">
                <xsl:value-of select="'Oboe primo'"/>
              </xsl:when>
              <xsl:when test=". = 'Ob. II'">
                <xsl:value-of select="'Oboe secondo'"/>
              </xsl:when>
              <xsl:when test=". = 'Fg. I'">
                <xsl:value-of select="'Fagotto primo'"/>
              </xsl:when>
              <xsl:when test=". = 'Fg. II'">
                <xsl:value-of select="'Fagotto secondo'"/>
              </xsl:when>
              <xsl:when test=". = 'Cor. I'">
                <xsl:value-of select="'Corno primo'"/>
              </xsl:when>
              <xsl:when test=". = 'Cor. II'">
                <xsl:value-of select="'Corno secondo'"/>
              </xsl:when>
              <xsl:when test=". = 'Ob. I on stage'">
                <xsl:value-of select="'Oboe primo on stage'"/>
              </xsl:when>
              <xsl:when test=". = 'Ob. II on stage'">
                <xsl:value-of select="'Oboe secondo on stage'"/>
              </xsl:when>
              <xsl:when test=". = 'Fag. on stage'">
                <xsl:value-of select="'Fagotto on stage'"/>
              </xsl:when>
              <xsl:when test=". = 'Cor. I on stage'">
                <xsl:value-of select="'Corno primo on stage'"/>
              </xsl:when>
              <xsl:when test=". = 'Cor. II on stage'">
                <xsl:value-of select="'Corno secondo on stage'"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="'No part found, please check!'"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
        </xsl:variable>
        
        <xsl:variable name="sources" select="tei:cell[9]" as="xs:string"/>
        <xsl:variable name="spots" select="normalize-space(tei:cell[10])" as="xs:string"/>
        <xsl:variable name="category" select="normalize-space(tei:cell[11])" as="xs:string"/>
        <xsl:variable name="note" select="tei:cell[12]"/>
        
        <!-- Wird das hier überhaupt benötigt? -->
        <!--<xsl:variable name="scene" as="xs:string">
          <xsl:choose>
            <xsl:when test="$table.scene = 'Eingang'"><?TODO ggf anderer begriff ?>
              <xsl:value-of select="$table.scene"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="'Scene ' || $table.scene"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>-->
        
        <xsl:element name="annot">
          <xsl:attribute name="type">editorialComment</xsl:attribute>
          <!-- führt zu Problemen bei den Edirom xQuerys -->
<!--          <xsl:attribute name="n" select="position()"/>-->
          <xsl:attribute name="xml:id" select="concat($annotIDPrefix, uuid:randomUUID())"></xsl:attribute>
          <xsl:attribute name="plist">
            <xsl:choose>
              
              <!-- Ist es eine reine Spotanmerkung? -->
              <xsl:when test="$spots != '' and $bar_first = ''">
                <xsl:variable name="spotsT" select="tokenize(normalize-space($spots), '; ')"/>
                <xsl:for-each select="$spotsT">
                  <xsl:variable name="spotT" select="tokenize(., ', ')"/>
                  <xsl:variable name="spotSurfaceID" select="$spotT[2]"/>
                  <xsl:variable name="spotSurfaceSourceDocURI" select="document-uri($sourceDocs[//mei:mei//mei:surface[@xml:id = $spotSurfaceID]])"/>
                  <xsl:variable name="spotID" select="concat('opera_zone_edition-', $editionID, '_', $spotT[3])"/>
                  <xsl:variable name="spotParticipantURI" select="concat('xmldb:exist:///db/contents/', substring-after($spotSurfaceSourceDocURI, 'OPERA-Edition/'), '#', $spotID, ' ')"/>
                  <xsl:value-of select="$spotParticipantURI"/>
                </xsl:for-each>                
                <!-- ToDo -->
              </xsl:when>
              
              <!-- Ist es eine takt- oder seg-basierte Anmerkung? -->
              <xsl:when test="$bar_first != '' or $seg_first != ''">
                
                <!-- Wie heißt der zugehörige mdiv? -->
                <xsl:variable name="actualMDIV" select="normalize-space($table.scene)" as="xs:string"/>
                <!-- Die gesuchte Konkordanz: -->
<!--                <xsl:variable name="actualConc" select="$editionConcordances[@name = $actualMDIV]" as="element()"/>-->
                <xsl:variable name="actualConcGroup" select="$editionConcordances//edi:group[@name = $actualMDIV]" as="element()"/>
                <!-- Teilnehmer der Startangabe -->
                <!--<xsl:variable name="concConnectionStart" as="element()">
                  <xsl:choose>
                    <xsl:when test="$actualConc//edi:group">
                      <xsl:copy-of select="$actualConc//edi:group[@name = 'Navigation by bar']//edi:connection[@name = $bar_first]"/>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:copy-of select="$actualConc//edi:connection[@name = $bar_first]"/>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:variable>-->
                <xsl:variable name="concConnectionStart" select="$actualConcGroup//edi:connection[@name = $bar_first] | $actualConcGroup//edi:connection[@name = concat('seg ', $seg_first)]" as="element()"/>
                
                <xsl:variable name="concPlistStart" select="$concConnectionStart/@plist"/>
                <xsl:variable name="concPlistStartT" select="tokenize($concPlistStart,' ')"/>
                
                <!--  DIE QUELLEN FINDEN: -->
                
                <!-- Welche Quellen werden benötigt? -->
                <xsl:variable name="sourcesT" select="tokenize($sources, ', ')" as="item()*"/>
                  <xsl:choose> 
                
                    <!-- Wenn es nur einen Takt gibt -->
                    <!-- Variante 1 und 2: -->
                    <xsl:when test="($bar_first != '' and $bar_last = '') or ($bar_last = $bar_first)">
                      <xsl:for-each select="$sourcesT">
                        
                        <!-- referenziertes Siglum -->
                        <xsl:variable name="sourceSearch" select="."/>
                        <xsl:for-each select="$concPlistStartT">
                          
                          <!-- URI des aktuellen Konkordanzteilnehmers -->
                          <xsl:variable name="concPlistStartTMemberSearch" select="."/>
                          
                          <!-- Siglum des aktuellen Konkordanzteilnehmers-->
                          <xsl:variable name="concPlistStartTMemberSearchSiglum" select="doc(concat($pathToEditionContents, '/', substring-after(substring-before($concPlistStartTMemberSearch, '#'), concat($editionIDPrefix, $editionID, '/')), '/'))/mei:mei//mei:identifier[@type = 'siglum']/text() | doc(concat($pathToEditionContents, '/', substring-after(substring-before($concPlistStartTMemberSearch, '#'), concat($editionIDPrefix, $editionID, '/')), '/'))/tei:TEI//tei:altIdentifier/tei:idno" as="xs:string"/>
                          <xsl:choose>
                            
                            <!-- Ist referenziertes Siglum = Siglum des Konkordanzteilnehmers? -->
                            <xsl:when test="$concPlistStartTMemberSearchSiglum = $sourceSearch">
                              <xsl:choose>
                                
                                <!-- Textsegmente sollen erstmal ignoriert werden -->
                                <xsl:when test="contains($concPlistStartTMemberSearch, 'seg_')">
                                  <xsl:text>HALLO!</xsl:text>
                                </xsl:when>
                                
                                <!-- Sind hier Stimmen referenziert? Dann mdiv, Taktnummern, Stimme(n) und Quelle identifizieren -->
                                <xsl:when test="contains($concPlistStartTMemberSearch, 'measure_edirom_mdiv_')">
                                  
                                  <!-- mdivID -->
                                  <xsl:variable name="mdivID" select="functx:substring-before-last(substring-after($concPlistStartTMemberSearch, '#measure_'), '_')"/>
                                  
                                  <!-- Taktnummern -->
                                  <xsl:variable name="mdivIdMeasureNo" select="functx:substring-after-last($concPlistStartTMemberSearch, '_')"/>
                                  
                                  <!-- Stimme(n) -->
                                  <!-- siehe $parts weiter oben -->
                                  
                                  <!-- lokaler Pfad zur Quellen-Datei -->
                                  <xsl:variable name="localSourceDoc" select="doc(concat($basePathToEditionContents, substring-before(substring-after($concPlistStartTMemberSearch, '/contents/'), '#'), ' '))" as="document-node()"/>
                                  
                                  <!-- der gesuchte mdiv -->
                                  <xsl:variable name="sourceDocMdiv" select="$localSourceDoc/mei:mei//mei:mdiv[@xml:id = $mdivID]" as="node()"/>
                                  
                                  <!-- alle parts in diesem mdiv -->
                                  <xsl:variable name="sourceDocMdivParts" select="$sourceDocMdiv//mei:part"/>
                                  
                                  <!-- alle gesuchten Takte in allen benötigten parts -->
                                  <xsl:variable name="sourceDocMdivPartsMeasureParticipants">
                                    <xsl:for-each select="$parts">
                                      <xsl:variable name="part" select="."/>
                                      <!-- alle Takt-IDs in diesem part, die die entsprechende Taktnummer haben -->
                                      <xsl:variable name="measureIDs" select="$sourceDocMdivParts[@label = $part]//mei:measure[@n = $mdivIdMeasureNo]/@xml:id"/>
                                      <!-- participant uris für @plist -->
                                      <xsl:variable name="measureParticipants">
                                        <xsl:for-each select="$measureIDs">
                                          <xsl:variable name="measureID" select="."/>
                                          <xsl:value-of select="concat(substring-before($concPlistStartTMemberSearch, '#'), '#', $measureID, ' ')"/>
                                        </xsl:for-each>
                                      </xsl:variable>
                                      <xsl:value-of select="$measureParticipants"/>
                                    </xsl:for-each>
                                    
                                  </xsl:variable>
                                  <!-- hier kommt dieser Teil der @plist -->
                                  <xsl:value-of select="$sourceDocMdivPartsMeasureParticipants"/>
                                </xsl:when>
                                
                                <!-- … wenn es nur normale Takte sind … -->
                                <xsl:otherwise>
                                  <xsl:choose>
                                    
                                    <!-- Umgebrochener Takt? -->
                                    <xsl:when test="contains($concPlistStartTMemberSearch, '?tstamp2')">
                                      
                                      <!-- URI der ersten Takthälfte -->
                                      <xsl:variable name="actualMeasureURI" select="substring-before($concPlistStartTMemberSearch, '?tstamp2')"/>
                                      
                                      <!-- ID der ersten Takthälfte -->
                                      <xsl:variable name="actualMeasureID" select="substring-after($actualMeasureURI, '#')"/>
                                      <!-- Wir gehen davon aus, dass ein Takt nur einmal umbrochen ist und die zweite Hälfte im mei direkt nach der ersten Hälfte verzeichnet ist. -->
                                      <!-- ID der zweiten Takthälfte im Quellendokument (direkt nach der ersten Takthälfte) -->
                                      <xsl:variable name="nextMeasureID" select="doc(concat($basePathToEditionContents, substring-before(substring-after($concPlistStartTMemberSearch, '/contents/'), '#'), ' '))//mei:measure[@xml:id = $actualMeasureID]/following-sibling::mei:measure[1]/@xml:id"/>
                                      
                                      <!-- URI der zweiten Takthälfte -->
                                      <xsl:variable name="nextMeasureURI" select="concat(substring-before($actualMeasureURI, '#'), '#', $nextMeasureID)"/>
                                      
                                      <!-- … und die beidenURIs für die @plist -->
                                      <xsl:value-of select="concat($actualMeasureURI, ' ', $nextMeasureURI, ' ')"/>
                                    </xsl:when>
                                    
                                    <!-- Ansonsten normal… -->
                                    <xsl:otherwise>
                                      <xsl:value-of select="concat($concPlistStartTMemberSearch, ' ')"/>
                                    </xsl:otherwise>
                                  </xsl:choose>
                                </xsl:otherwise>
                              </xsl:choose>
                            </xsl:when>
                            <xsl:otherwise/>
                          </xsl:choose>
                        </xsl:for-each>
                      </xsl:for-each>
                    </xsl:when>
                
                    <!-- Taktstrecken -->
                    <xsl:when test="number($bar_last) > number($bar_first)">
                      
                      <!--<xsl:variable name="annotConcConnectionStart" select="$actualConc//edi:group[@name = 'Navigation by bar']//edi:connection[@name = $bar_first] | $actualConc//edi:connection[@name = $bar_first]" as="node()"/>-->
                      <xsl:variable name="annotConcConnectionStart" select="$actualConcGroup//edi:connection[@name = $bar_first]" as="node()"/>
                      <xsl:variable name="annotConcConnectionStartPos" select="count($annotConcConnectionStart/preceding-sibling::*)+1."/>
                      
                      <!--<xsl:variable name="annotConcConnectionEnd" select="$actualConc//edi:group[@name = 'Navigation by bar']//edi:connection[@name = $bar_last] | $actualConc//edi:connection[@name = $bar_last]"/>-->
                      <xsl:variable name="annotConcConnectionEnd" select="$actualConcGroup//edi:connection[@name = $bar_last]"/>
                      <xsl:variable name="annotConcConnectionEndPos" select="count($annotConcConnectionEnd/preceding-sibling::*)+1."/>
                      
                      <!--<xsl:variable name="concPlistsJoined" as="attribute()*">
                        <xsl:for-each select="$actualConc//edi:connection[count(./preceding-sibling::*)+1. &gt;= $annotConcConnectionStartPos and count(./preceding-sibling::*)+1. &lt;= $annotConcConnectionEndPos]">
                          <xsl:copy-of select="./@plist"/>
                        </xsl:for-each>
                      </xsl:variable>-->
                      <xsl:variable name="concPlistsJoined" as="attribute()*">
                        <xsl:for-each select="$actualConcGroup//edi:connection[count(./preceding-sibling::*)+1. &gt;= $annotConcConnectionStartPos and count(./preceding-sibling::*)+1. &lt;= $annotConcConnectionEndPos]">
                          <xsl:copy-of select="./@plist"/>
                        </xsl:for-each>
                      </xsl:variable>
                      
                      <xsl:variable name="concPlistsJoinedT" select="tokenize(string-join($concPlistsJoined, ' '), ' ')"/>
                      
                      <xsl:for-each select="$sourcesT">
                        <xsl:variable name="sourceSearch" select="."/>
                        <xsl:for-each select="$concPlistsJoinedT">
                          
                            <!-- URI des aktuellen Konkordanzteilnehmers -->
                            <xsl:variable name="concPlistsJoinedTMemberSearch" select="."/>
                          
                            <!-- Siglum des aktuellen Konkordanzteilnehmers-->
                          <xsl:variable name="concPlistsJoinedTMemberSearchSiglum" select="doc(concat($pathToEditionContents, '/', substring-after(substring-before($concPlistsJoinedTMemberSearch, '#'), concat($editionIDPrefix, $editionID, '/')), '/'))/mei:mei//mei:identifier[@type = 'siglum']/text() | doc(concat($pathToEditionContents, '/', substring-after(substring-before($concPlistsJoinedTMemberSearch, '#'), concat($editionIDPrefix, $editionID, '/')), '/'))/tei:TEI//tei:altIdentifier/tei:idno/text()" as="xs:string"/>
                          
                            <xsl:choose>
                              
                              <!-- Ist referenziertes Siglum = Siglum des Konkordanzteilnehmers? -->
                              <xsl:when test="$concPlistsJoinedTMemberSearchSiglum = $sourceSearch">
                                
                                <!-- Sind hier Stimmentakte oder (nur) Partiturtakte referenziert? -->
                                <xsl:choose>
                                  <!-- Textsegmente sollen erstmal ignoriert werden -->
                                  <xsl:when test="contains($concPlistsJoinedTMemberSearch, '_seg')"/>
                                  
                                  <!-- Sind hier Stimmen referenziert? Dann mdiv, Taktnummern, Stimme(n) und Quelle identifizieren -->
                                  <xsl:when test="contains($concPlistsJoinedTMemberSearch, 'measure_edirom_mdiv_')">
                                    
                                    <!-- mdivID -->
                                    <xsl:variable name="mdivID" select="functx:substring-before-last(substring-after($concPlistsJoinedTMemberSearch, '#measure_'), '_')"/>
                                    
                                    <!-- Taktnummern -->
                                    <xsl:variable name="mdivIdMeasureNo" select="functx:substring-after-last($concPlistsJoinedTMemberSearch, '_')"/>
                                    
                                    <!-- Stimme(n) -->
                                    <!-- siehe $parts weiter oben -->
                                    
                                    <!-- lokaler Pfad zur Quellen-Datei -->
                                    <xsl:variable name="localSourceDoc" select="doc(concat($basePathToEditionContents, substring-before(substring-after($concPlistsJoinedTMemberSearch, '/contents/'), '#'), ' '))" as="document-node()"/>
                                    
                                    <!-- der gesuchte mdiv -->
                                    <xsl:variable name="sourceDocMdiv" select="$localSourceDoc/mei:mei//mei:mdiv[@xml:id = $mdivID]" as="node()"/>
                                    
                                    <!-- alle parts in diesem mdiv -->
                                    <xsl:variable name="sourceDocMdivParts" select="$sourceDocMdiv//mei:part"/>
                                    
                                    <!-- alle gesuchten Takte in allen benötigten parts -->
                                    <xsl:variable name="sourceDocMdivPartsMeasureParticipants">
                                      <!-- wenn 'all' alle measure aus mdiv mit n= measureNo, ansonsten parts -->
                                      <xsl:choose>
                                        <!-- wenn $parts nur einen Teilnehmer hat und dieser 'all' ist,
                                              brauchen wir einfach alle Takte -->
                                        <xsl:when test="count($parts) = 1 and $parts[1] = 'all'">
                                          <xsl:variable name="allParts" select="$sourceDocMdivParts/@label/string()"/>
                                          <xsl:variable name="countParts" select="count($allParts)"/>
                                          <xsl:for-each select="$allParts">
                                            <xsl:variable name="part" select="."/>
                                            <!-- alle Takt-IDs in diesem part, die die entsprechende Taktnummer haben -->
                                            
                                            <!-- alle Takte in diesem part -->
                                            <xsl:variable name="partMeasures" select="$sourceDocMdivParts[@label = $part]//mei:measure"/>
                                            <!-- all Takt-IDs, die mit $mdivIdMeasureNo in Verbindung stehen -->
                                            <xsl:variable name="measureIDs">
                                              <xsl:for-each select="$partMeasures">
                                                <xsl:variable name="partMeasure" select="."/>
                                                <xsl:choose>
                                                  <!-- sind es zusammengefasste Takte? -->
                                                  <xsl:when test="contains($partMeasure/@n, '-')">
                                                    <xsl:variable name="partMeasureFirst">
                                                      <xsl:value-of select="number(substring-before($partMeasure/@n/string(), '-'))"/>
                                                    </xsl:variable>
                                                    <xsl:variable name="partMeasureLast">
                                                      <xsl:value-of select="number(substring-after($partMeasure/@n/string(), '-'))"/>
                                                    </xsl:variable>
                                                    <xsl:if test="$partMeasureFirst &lt;= number($mdivIdMeasureNo) and $partMeasureLast &gt;= number($mdivIdMeasureNo)">
                                                      <xsl:value-of select="concat($partMeasure/@xml:id/string(), ' ')"/>
                                                    </xsl:if>
                                                  </xsl:when>
                                                  <!-- ansonsten einfach alle anderen -->
                                                  <xsl:otherwise>
                                                    <xsl:value-of select=".[@n = $mdivIdMeasureNo]/@xml:id/string()"/>
                                                  </xsl:otherwise>
                                                  
                                                </xsl:choose>
                                              </xsl:for-each>
                                            </xsl:variable>
                                            
                                            <!-- participant uris für @plist -->
                                            <xsl:variable name="measureParticipants">
                                              <xsl:for-each select="distinct-values(tokenize($measureIDs, ' '))">
                                                <xsl:variable name="measureID" select="."/>
                                                  <xsl:if test="$measureID != ''">
                                                    <xsl:value-of select="concat(substring-before($concPlistsJoinedTMemberSearch, '#'), '#', $measureID, ' ')"/>
                                                  </xsl:if>
                                              </xsl:for-each>
                                            </xsl:variable>
                                            <xsl:value-of select="$measureParticipants"/>
                                          </xsl:for-each>
                                        </xsl:when>
                                        
                                        
                                        
                                        <!-- ansonsten die entsprechenden $parts abarbeiten -->
                                        <xsl:otherwise>
                                          <xsl:for-each select="$parts">
                                            <xsl:variable name="part" select="."/>
                                            <!-- alle Takt-IDs in diesem part, die die entsprechende Taktnummer haben -->
                                            <xsl:variable name="measureIDs" select="$sourceDocMdivParts[@label = $part]//mei:measure[@n = $mdivIdMeasureNo]/@xml:id"/>
                                            <!-- participant uris für @plist -->
                                            <xsl:variable name="measureParticipants">
                                              <xsl:for-each select="$measureIDs">
                                                <xsl:variable name="measureID" select="."/>
                                                <xsl:value-of select="concat(substring-before($concPlistsJoinedTMemberSearch, '#'), '#', $measureID, ' ')"/>
                                              </xsl:for-each>
                                            </xsl:variable>
                                            <xsl:value-of select="$measureParticipants"/>
                                          </xsl:for-each>
                                        </xsl:otherwise>
                                      </xsl:choose>
                                      
                                      
                                    </xsl:variable>
                                    <!-- hier kommt dieser Teil der @plist -->
                                    <xsl:value-of select="$sourceDocMdivPartsMeasureParticipants"/>
                                  </xsl:when>
                                  
                                  <!-- … wenn es nur normale Takte sind … -->
                                  <xsl:otherwise>
                                    <xsl:choose>
                                      
                                      <!-- Umbrochener Takt? -->
                                      <xsl:when test="contains($concPlistsJoinedTMemberSearch, '?tstamp2')">
                                        
                                        <!-- URI der ersten Takthälfte -->
                                        <xsl:variable name="actualMeasureURI" select="substring-before($concPlistsJoinedTMemberSearch, '?tstamp2')"/>
                                        
                                        <!-- ID der ersten Takthälfte -->
                                        <xsl:variable name="actualMeasureID" select="substring-after($actualMeasureURI, '#')"/>
                                        <!-- Wir gehen davon aus, dass ein Takt nur einmal umbrochen ist und die zweite Hälfte im mei direkt nach der ersten Hälfte verzeichnet ist. -->
                                        <!-- ID der zweiten Takthälfte im Quellendokument (direkt nach der ersten Takthälfte) -->
                                        <xsl:variable name="nextMeasureID" select="doc(concat($basePathToEditionContents, substring-before(substring-after($concPlistsJoinedTMemberSearch, '/contents/'), '#'), ' '))//mei:measure[@xml:id = $actualMeasureID]/following-sibling::mei:measure[1]/@xml:id"/>
                                        
                                        <!-- URI der zweiten Takthälfte -->
                                        <xsl:variable name="nextMeasureURI" select="concat(substring-before($actualMeasureURI, '#'), '#', $nextMeasureID)"/>
                                        
                                        <!-- … und die beidenURIs für die @plist -->
                                        <xsl:value-of select="concat($actualMeasureURI, ' ', $nextMeasureURI, ' ')"/>
                                      </xsl:when>
                                      
                                      <!-- Ansonsten normal… -->
                                      <xsl:otherwise>
                                        <xsl:value-of select="concat($concPlistsJoinedTMemberSearch, ' ')"/>
                                      </xsl:otherwise>
                                    </xsl:choose>
                                  </xsl:otherwise>
                                </xsl:choose>
                              </xsl:when>
                              <xsl:otherwise/>
                            </xsl:choose>
                        </xsl:for-each>
                      </xsl:for-each>
                    </xsl:when>
                
                    <!-- Textsegmente -->
                    <xsl:when test="$bar_first = '' and $bar_last = '' and $seg_first != '' and $seg_last = ''">
                      <xsl:value-of select="$bar_first"/>
                    </xsl:when>
                    
                    <xsl:otherwise>
                      <xsl:value-of select="'nix'"/>
                    </xsl:otherwise>
                
                  </xsl:choose>
              </xsl:when>
            </xsl:choose>
          </xsl:attribute>
          
          <xsl:element name="title">
            <!-- scene, "bar(s)? bar_first("–"bar_last)?, system -->
            <xsl:variable name="titleBarOrSegIndicator">
              <xsl:choose>
                
                <!-- only spot -->
                <xsl:when test="$bar_first = '' and $bar_last = '' and $seg_first = '' and $seg_last = '' and $spotTitle != ''">
                  <xsl:value-of select="$spotTitle"/>
                </xsl:when>
                <!-- no bars, no segs., so leave empty… -->
                <xsl:when test="$bar_first = '' and $bar_last = '' and $seg_first = '' and $seg_last = ''">Hier passt etwas nicht. Bitte prüfen!</xsl:when>
                <xsl:when test="$bar_first = '' and $bar_last = '' and $seg_first != '' and $seg_last = ''">
                  <xsl:value-of select="concat('seg ', $seg_first, ', ')"/>
                </xsl:when>
                <!-- no bars, different segs. -->
                <xsl:when test="$bar_first = '' and $bar_last = '' and $seg_first != $seg_last">
                  <xsl:value-of select="concat('seg ', $seg_first, '–', $seg_last, ', ')"/>
                </xsl:when>
                <!-- no bars, same segs. -->
                <xsl:when test="$bar_first = '' and $bar_last = '' and $seg_first = $seg_last">
                  <xsl:value-of select="concat('seg ', $seg_first, ', ')"/>
                </xsl:when>
                <!-- only first bar -->
                <xsl:when test="$bar_first != '' and $bar_last = ''">
                  <xsl:value-of select="concat('bar ', $bar_first, ', ')"/>
                </xsl:when>
                <!-- only first bar and first seg. -->
                <xsl:when test="$bar_first != '' and $bar_last = '' and $seg_first != '' and $seg_last = ''">
                  <xsl:value-of select="concat('bar ', $bar_first, ', seg ', $seg_first)"/>
                </xsl:when>
                <!-- same bars -->
                <xsl:when test="$bar_last = $bar_first">
                  <xsl:value-of select="concat('bar ', $bar_first, ', ')"/>
                </xsl:when>
                <!-- different bars, no segs. -->
                <xsl:when test="$bar_last != $bar_first and $seg_first = '' and $seg_last = ''" >
                  <xsl:value-of select="concat('bars ', $bar_first, '–', $bar_last, ', ')"/>
                </xsl:when>
                <!-- different bars, different segs.-->
                <xsl:when test="$bar_first != $bar_last and $seg_first != $seg_last">
                  <xsl:value-of select="concat('bars ', $bar_first, '–', $bar_last, ', seg ', $seg_first, '–', $seg_last, ', ')"/>
                </xsl:when>
                <!-- when anything matches, print error message: -->
                <xsl:otherwise>Something went wrong, please check the template!</xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:value-of select="concat(normalize-space($table.scene), ', ', $titleBarOrSegIndicator, $system)"/>
          </xsl:element>
          <xsl:choose>
            <xsl:when test="not($note/tei:p)">
              <xsl:element name="p">
                <xsl:apply-templates select="$note"/>
              </xsl:element>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates select="$note"/>
            </xsl:otherwise>
          </xsl:choose>
          <!-- OPERA: only one priority …-->
          <xsl:element name="ptr">
            <xsl:attribute name="type">priority</xsl:attribute>
            <xsl:attribute name="target">#ediromAnnotPrio1</xsl:attribute>
          </xsl:element>
          <!-- … but 1-3 categories -->
          <xsl:element name="ptr">
            <xsl:attribute name="type">categories</xsl:attribute>
            <xsl:attribute name="target">
              <xsl:variable name="targets">
                <xsl:for-each select="tokenize(normalize-space($category), ', ')">
                  <xsl:choose>
                    <xsl:when test=". = 'M'">#ediromAnnotCategory_Music </xsl:when>
                    <xsl:when test=". = 'T'">#ediromAnnotCategory_Text </xsl:when>
                    <xsl:when test=". = 'S'">#ediromAnnotCategory_Stage </xsl:when>
                    <xsl:otherwise>Something went wrong, please check the template!</xsl:otherwise>
                  </xsl:choose>
                </xsl:for-each>
              </xsl:variable>
              <xsl:value-of select="tokenize($targets)"/>
            </xsl:attribute>
          </xsl:element>
        </xsl:element>
      </xsl:for-each>
    </xsl:element>
  </xsl:template>
  
  <xd:doc>
    <xd:desc/>
  </xd:doc>
  <xsl:template match="tei:p">
    <xsl:element name="p">
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>
  
  <xd:doc>
    <xd:desc/>
  </xd:doc>
  <xsl:template match="tei:hi">
    <xsl:choose><?TODO italic+sup ?>
      <xsl:when test="contains(@rend,'italic')">
        <xsl:element name="rend">
          <xsl:attribute name="fontstyle" select="'italic'"/>
            <xsl:apply-templates/>
        </xsl:element>
      </xsl:when>
      <xsl:when test="contains(@rend,'sup')">
        <xsl:element name="rend">
          <xsl:attribute name="rend" select="'sup'"/>
          <xsl:apply-templates/>
        </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xd:doc>
    <xd:desc/>
  </xd:doc>
  <xsl:template match="tei:figure">
    <xsl:element name="fig">
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>
  
  <xd:doc>
    <xd:desc/>
  </xd:doc>
  <xsl:template match="tei:graphic">
    <xsl:element name="graphic">
      <xsl:attribute name="target" select="'edition-74338557/graphics/'"></xsl:attribute>
      <xsl:processing-instruction name="JS">TODO</xsl:processing-instruction>
    </xsl:element>
  </xsl:template>
  
  <xd:doc>
    <xd:desc/>
  </xd:doc>
  <xsl:template match="tei:note"/>
  
</xsl:stylesheet>