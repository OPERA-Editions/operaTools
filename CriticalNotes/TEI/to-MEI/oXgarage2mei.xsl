<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:mei="http://www.music-encoding.org/ns/mei"
  xmlns:edi="http://www.edirom.de/ns/1.3"
  xmlns:uuid="java:java.util.UUID"
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
    
  <!-- ID of MEI work file. -->
  <xsl:variable name="workID"></xsl:variable>
  
  <!-- ID of EDIROM edition file. -->
  <xsl:variable name="editionID"></xsl:variable>
  
  <!-- If there is a prefix ('edtion-' etc.) to the edition's ID, put it here! -->
  <xsl:variable name="editionIDPrefix"></xsl:variable>
  
  <!-- Choose your annotation ID's prefix -->
  <xsl:variable name="annotIDPrefix">edirom_annot_</xsl:variable>
  
  <!-- The relative path to the edition's root content folder, seen from this xslt's folder. -->
  <xsl:variable name="basePathToEditionContents">../../../../</xsl:variable>
  
  <!-- Do not change from here, otherwise you know what you are doing! -->
  <xsl:variable name="pathToEditionContents">
    <xsl:value-of select="concat($basePathToEditionContents, $editionIDPrefix, $editionID)"/>
  </xsl:variable>
  <xsl:variable name="sourceDocs" select="collection(concat($pathToEditionContents, '/sources?select=*.xml'))"/>
  <xsl:variable name="editionDoc" select="doc(concat($pathToEditionContents, '/', $editionIDPrefix, $editionID, '.xml'))"/>
  <xsl:variable name="editionConcordances" select="$editionDoc//edi:work[@xml:id = $workID]/edi:concordances//edi:concordance"/>
  
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
  
  <xsl:template match="/">
    <xsl:element name="annot">
      <xsl:attribute name="type">criticalCommentary</xsl:attribute>
      
      <xsl:for-each select="(//tei:table[@xml:id='Table1']/tei:row)[position() = 2]"><!-- position()>1 | 56-->
        <xsl:variable name="no" select="tei:cell[1]"/>
        <xsl:variable name="bar_first" select="tei:cell[2]"/>
        <xsl:variable name="bar_last" select="tei:cell[3]"/>
        <xsl:variable name="table.scene" select="tei:cell[4]"/>
        <xsl:variable name="seg_first" select="tei:cell[5]"/>
        <xsl:variable name="seg_last" select="tei:cell[6]"/>
        <xsl:variable name="system" select="tei:cell[7]"/>
        <xsl:variable name="sources" select="tei:cell[8]"/>
        <xsl:variable name="category" select="tei:cell[9]"/>
        <xsl:variable name="note" select="tei:cell[10]"/>
        
        <xsl:variable name="scene">
          <xsl:choose>
            <xsl:when test="$table.scene = 'Eingang'"><?TODO ggf anderer begriff ?>
              <xsl:value-of select="$table.scene"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="'Scene ' || $table.scene"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:element name="annot">
          <xsl:attribute name="type">editorialComment</xsl:attribute>
          <xsl:attribute name="n" select="position()"/>
          <xsl:attribute name="xml:id" select="concat($annotIDPrefix, uuid:randomUUID())"></xsl:attribute>
          <xsl:attribute name="plist">
            <xsl:variable name="actualMDIV" select="table.scene"/>
            <xsl:variable name="actualConc" select="$editionConcordances[@name = $actualMDIV]"/>
            <xsl:variable name="concPlistStart" select="$actualConc//edi:connection[@name = $bar_first]"/>
            <xsl:variable name="concPlistEnd" select="$actualConc//edi:connection[@name = $bar_last]"/>
            
            <!-- erster Takt, letzter Takt
                  concPlist erster Takt, concPlist zweiter Takt
                  beteiligte Quellen aus Anotation
                  Plist(s) nach Quellen filtern und als neue Plist ausgeben. -->
            <!--<xsl:value-of select="$editionConcordances"/>-->
            <!--<xsl:for-each select="tokenize($sources, ', ')">
              <xsl:value-of select="."/>
            </xsl:for-each>-->
          </xsl:attribute>
          <?TODO @plist ?>
          <xsl:element name="title">
            <!-- scene, "bar(s)? bar_first("–"bar_last)?, system -->
            <xsl:variable name="titleBarOrSegIndicator">
              <xsl:choose>
                <!-- no bars, no segs., so leave empty… -->
                <xsl:when test="$bar_first = '' and $bar_last = '' and $seg_first = '' and $seg_last = ''"/>
                <!-- no bars, first seg. -->
                <xsl:when test="$bar_first = '' and $bar_last = '' and $seg_first != '' and $seg_last = ''">
                  <xsl:value-of select="concat('seg. ', $seg_first, ', ')"/>
                </xsl:when>
                <!-- no bars, different segs. -->
                <xsl:when test="$bar_first = '' and $bar_last = '' and $seg_first != $seg_last">
                  <xsl:value-of select="concat('seg. ', $seg_first, '–', $seg_last, ', ')"/>
                </xsl:when>
                <!-- no bars, same segs. -->
                <xsl:when test="$bar_first = '' and $bar_last = '' and $seg_first = $seg_last">
                  <xsl:value-of select="concat('seg. ', $seg_first, ', ')"/>
                </xsl:when>
                <!-- only first bar -->
                <xsl:when test="$bar_first != '' and $bar_last = ''">
                  <xsl:value-of select="concat('bar ', $bar_first, ', ')"/>
                </xsl:when>
                <!-- only first bar and first seg. -->
                <xsl:when test="$bar_first != '' and $bar_last = '' and $seg_first != '' and $seg_last = ''">
                  <xsl:value-of select="concat('bar ', $bar_first, ', seg. ', $seg_first)"/>
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
                  <xsl:value-of select="concat('bars ', $bar_first, '–', $bar_last, ', seg. ', $seg_first, '–', $seg_last, ', ')"/>
                </xsl:when>
                <!-- when anything matches, print error message: -->
                <xsl:otherwise>Something went wrong, please check the template!</xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:value-of select="concat($scene, ', ', $titleBarOrSegIndicator, $system)"/>
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
              <xsl:for-each select="tokenize(normalize-space($category), ', ')">
                <xsl:choose>
                  <xsl:when test=". = 'M'">#ediromAnnotCategory_Music </xsl:when>
                  <xsl:when test=". = 'T'">#ediromAnnotCategory_Text </xsl:when>
                  <xsl:when test=". = 'S'">#ediromAnnotCategory_Stage </xsl:when>
                  <xsl:otherwise>Something went wrong, please check the template!</xsl:otherwise>
                </xsl:choose>
              </xsl:for-each>
            </xsl:attribute>
          </xsl:element>
        </xsl:element>
      </xsl:for-each>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="tei:p">
    <xsl:element name="p">
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="tei:hi">
    <xsl:choose><?TODO italic+sup ?>
      <xsl:when test="contains(@rend,'italic')">
        <xsl:element name="rend">
          <xsl:attribute name="rend" select="'italic'"/>
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
  
  <xsl:template match="tei:figure">
    <xsl:element name="fig">
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="tei:graphic">
    <xsl:element name="graphic">
      <xsl:attribute name="target" select="'edition-74338557/graphics/'"></xsl:attribute>
      <xsl:processing-instruction name="JS">TODO</xsl:processing-instruction>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="tei:note"/>
  
</xsl:stylesheet>