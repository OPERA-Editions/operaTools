<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:mei="http://www.music-encoding.org/ns/mei"
    exclude-result-prefixes="xs"
    version="2.0">
    
    <xsl:output omit-xml-declaration="no" indent="yes" encoding="UTF-8" method="xml" media-type="xml"/>
    
    <xsl:template match="/">
        <xsl:variable name="editionID">edition-74338558</xsl:variable>
        <xsl:for-each select=".//mei:mei">
            <xsl:variable name="IDstring" select="./@xml:id/string()"/>
            <xsl:result-document href="../../{$editionID}/sources/comments/{$IDstring}.xml">
                <xsl:copy-of select="."></xsl:copy-of>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>
    
</xsl:stylesheet>
