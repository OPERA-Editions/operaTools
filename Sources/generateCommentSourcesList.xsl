<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:mei="http://www.music-encoding.org/ns/mei"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs"
    version="2.0">
    
    <xsl:output omit-xml-declaration="no" indent="yes" encoding="UTF-8" method="xml" media-type="xml"/>
    
    <xsl:template match="/">
        <xsl:variable name="editionID">edition-74338558</xsl:variable>
        <xsl:result-document href="../../{$editionID}/sources/comments/comment_sources_list.xml">
            <tei:TEI xmlns="http://www.tei-c.org/ns/1.0">
                <tei:teiHeader>
                    <tei:fileDesc>
                        <tei:titleStmt>
                            <tei:title>Link list for comment sources windows</tei:title>
                        </tei:titleStmt>
                        <tei:publicationStmt>
                            <tei:p>nothing</tei:p>
                        </tei:publicationStmt>
                        <tei:sourceDesc>
                            <tei:p>nothing</tei:p>
                        </tei:sourceDesc>
                    </tei:fileDesc>
                </tei:teiHeader>
                <tei:text>
                    <tei:body>
                        <tei:p>
                            <tei:list>
                                <xsl:for-each select=".//mei:mei">
                                    <xsl:sort select="./@xml:id/string()"></xsl:sort>
                                    <xsl:variable name="IDstring" select="./@xml:id/string()"/>
                                    <xsl:variable name="target" select="concat('xmldb:exist:///db/contents/edition-74338558/sources/comments/', $IDstring, '.xml')"/>
                                    <tei:item><tei:ref target="{$target}"><xsl:value-of select="$IDstring"/></tei:ref></tei:item>
                                </xsl:for-each>
                            </tei:list>
                        </tei:p>
                    </tei:body>
                </tei:text>
            </tei:TEI>
        
        </xsl:result-document>
    </xsl:template>
    
</xsl:stylesheet>
