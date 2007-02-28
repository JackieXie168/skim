<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	        version="1.0">

<xsl:import href="http://docbook.sourceforge.net/release/xsl/current/htmlhelp/htmlhelp.xsl" />

<xsl:template name="body.attributes">
   <link rel="stylesheet" type="text/css" href="common/style1.css"/>
</xsl:template>
<xsl:variable name="suppress.navigation">0</xsl:variable>
<xsl:variable name="use.id.as.filename">1</xsl:variable>
<xsl:variable name="generate.book.toc">1</xsl:variable>
<xsl:variable name="toc.section.depth">3</xsl:variable>
<xsl:variable name="generate.toc.section.depth">3</xsl:variable>
<xsl:variable name="section.autolabel">1</xsl:variable>

</xsl:stylesheet>


