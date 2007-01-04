<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		version="1.0">

  <xsl:include href="http://docbook.sourceforge.net/release/xsl/current/xhtml/chunk.xsl"/>

  <xsl:variable name="use.id.as.filename">1</xsl:variable>
  <xsl:variable name="html.ext">.tkl</xsl:variable>
  <xsl:variable name="navig.showtitles">0</xsl:variable>
  <xsl:param name="chunker.output.omit-xml-declaration" select="'yes'"/> 

<xsl:template name="chunk-element-content">
  <xsl:param name="prev"/>
  <xsl:param name="next"/>

  <xsl:element name="document">
    <title>
       <xsl:apply-templates select="." mode="object.title.markup"/>
    </title>
    <nonews>1</nonews>
    <body>
      <xsl:call-template name="body.attributes"/>
      <xsl:call-template name="user.header.navigation"/>

      <xsl:call-template name="header.navigation">
        <xsl:with-param name="prev" select="$prev"/>
        <xsl:with-param name="next" select="$next"/>
      </xsl:call-template>

      <xsl:call-template name="user.header.content"/>

      <xsl:apply-imports/>

      <xsl:call-template name="user.footer.content"/>

      <xsl:call-template name="footer.navigation">
        <xsl:with-param name="prev" select="$prev"/>
        <xsl:with-param name="next" select="$next"/>
      </xsl:call-template>

      <xsl:call-template name="user.footer.navigation"/>
    </body>
  </xsl:element>
</xsl:template>

</xsl:stylesheet>


