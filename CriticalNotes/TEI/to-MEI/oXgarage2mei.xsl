<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:mei="http://www.music-encoding.org/ns/mei"
  xmlns:uuid="java:java.util.UUID"
  xmlns="http://www.music-encoding.org/ns/mei"
  exclude-result-prefixes="xs xd"
  version="3.0">
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Created on:</xd:b> Nov 14, 2017</xd:p>
      <xd:p><xd:b>Author:</xd:b> bwb</xd:p>
      <xd:p>Postprocessing needed: check for mei:rend with trailing whitespace that should come after the closing tag</xd:p>
    </xd:desc>
  </xd:doc>
  
  <xsl:output indent="yes" omit-xml-declaration="yes"></xsl:output>
  
  
  <!--<annot type="criticalCommentary" xmlns="http://www.music-encoding.org/ns/mei">
    <annot type="editorialComment" xml:id="edirom_annot_${uuid}" plist="xmldb:exist:///db/contents/edition-74338557/([Sources])">
      <title>bla blub</title>
      <p>test anmerkung</p><!-\- [Note] -\->
      <ptr type="priority" target="#ediromAnnotPrio1"/>
      <ptr type="categories" target="#ediromDefaultCategory_Articulation"/><!-\- [Category] -\->
    </annot>
  </annot>-->
  
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
      
      <xsl:for-each select="(//tei:table[@xml:id='Table1']/tei:row)[position()>1]"><!-- position()>1 | 56-->
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
          <xsl:attribute name="xml:id" select="concat('opera_annot_', uuid:randomUUID())"></xsl:attribute>
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
                <xsl:otherwise>Hier stimmt was nicht! Bitte die Taktangabe in der Vorlage überprüfen!</xsl:otherwise>
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