<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output indent="no" method="text"/>
	
	<xsl:param name="debug" select="1"/>
	
	<xsl:template match="/">
		<xsl:text>

</xsl:text>
		<xsl:apply-templates />
		<xsl:text>

</xsl:text>
	</xsl:template>
	
	<xsl:template match="*">
		<xsl:if test="$debug!=0">
			<xsl:message>no template for element: <xsl:value-of select="local-name(.)"/>
			</xsl:message>
		</xsl:if>
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="title" />
	
	<xsl:template match="text()">
		<xsl:variable name="text"><xsl:call-template name="break"/></xsl:variable>
		<xsl:call-template name="doublespace">
			<xsl:with-param name="text" select="$text" />
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template name="break">
		<xsl:param name="text" select="."/>
		<xsl:choose>
			<xsl:when test="contains($text, '&#xa;')">
				<xsl:value-of select="substring-before($text, '&#xa;')"/>
				<xsl:text> </xsl:text>
				<xsl:call-template name="break">
					<xsl:with-param name="text" select="substring-after($text,'&#xa;')"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$text"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="doublespace">
		<xsl:param name="text" select="." />
		<xsl:choose>
			<xsl:when test="contains($text, '  ')">
				<xsl:call-template name="doublespace">
					<xsl:with-param name="text"><xsl:value-of select="substring-before($text, '  ')"/><xsl:text> </xsl:text><xsl:value-of select="substring-after($text, '	  ')"/></xsl:with-param>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$text"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="bookinfo|articleinfo|partinfo|chapterinfo|sectioninfo|appendixinfo|prefaceinfo" />
	
	<xsl:template match="book|article|part|chapter|section|appendix|preface">
		<xsl:call-template name="make.title" />
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="para|simpara">
		<xsl:if test="count(preceding-sibling::*)!=0">
			<xsl:text>
</xsl:text>
		</xsl:if>
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="itemizedlist/listitem">
		<xsl:text>
</xsl:text>
		<xsl:call-template name="make.listdecoration" />
		<xsl:text> </xsl:text>
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="itemizedlist|orderedlist">
		<xsl:text>
</xsl:text>
		<xsl:apply-templates />
		<xsl:text>
</xsl:text>
	</xsl:template>
	
	<xsl:template match="blockquote">
		<xsl:text>{quote}
</xsl:text>
		<xsl:apply-templates />
		<xsl:text>{quote}
</xsl:text>
	</xsl:template>
	
	<xsl:template match="note|tip|caution|warning">
		<xsl:text>{panel:</xsl:text><xsl:call-template name="make.paneltitle"/><xsl:text>}
</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>
{panel}</xsl:text>
	</xsl:template>
	
	<xsl:template name="make.paneltitle">
		<!--
		<xsl:choose>
			<xsl:when test="local-name(.)='note'">
				<xsl:text></xsl:text>
			</xsl:when>
			<xsl:when test="local-name(.)='tip'">
				<xsl:text></xsl:text>
			</xsl:when>
			<xsl:when test="local-name(.)='caution'">
				<xsl:text></xsl:text>
			</xsl:when>
			<xsl:when test="local-name(.)='warning'">
				<xsl:text></xsl:text>
			</xsl:when>
		</xsl:choose>
		-->
		<xsl:choose>
			<xsl:when test="local-name(.)='note'">
				<xsl:text>title=Note</xsl:text>
			</xsl:when>
			<xsl:when test="local-name(.)='tip'">
				<xsl:text>title=Tip</xsl:text>
			</xsl:when>
			<xsl:when test="local-name(.)='caution'">
				<xsl:text>title=Caution</xsl:text>
			</xsl:when>
			<xsl:when test="local-name(.)='warning'">
				<xsl:text>title=Warning</xsl:text>
			</xsl:when>
		</xsl:choose>
		<xsl:if test="title">
			<xsl:text> - </xsl:text><xsl:apply-templates select="title/node()"/>
		</xsl:if>
		<xsl:choose>
			<xsl:when test="local-name(.)='note'">
				<xsl:text>|borderStyle=dashed|borderColor=#ccc|titleBGColor=#cccccc|bgColor=#dddddd</xsl:text>
			</xsl:when>
			<xsl:when test="local-name(.)='tip'">
				<xsl:text>|borderStyle=dashed|borderColor=#ccc|titleBGColor=#aaaaaa|bgColor=#eeeeee</xsl:text>
			</xsl:when>
			<xsl:when test="local-name(.)='caution'">
				<xsl:text>|borderStyle=dashed|borderColor=#ccc|titleBGColor=#ffffaa|bgColor=#ffffee</xsl:text>
			</xsl:when>
			<xsl:when test="local-name(.)='warning'">
				<xsl:text>|borderStyle=dashed|borderColor=#ccc|titleBGColor=#ffaaaa|bgColor=#FFeeee</xsl:text>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="blockquote/blockquote">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="quote">
		<xsl:text>??</xsl:text>
		<xsl:apply-templates />
		<xsl:text>??</xsl:text>
	</xsl:template>
	
	<xsl:template match="quote//quote">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="orderedlist//itemizedlist|orderedlist//orderedlist|itemizedlist//itemizedlist|itemizedlist//orderedlist">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="orderedlist/listitem|procedure/step">
		<xsl:text>
</xsl:text>
		<xsl:call-template name="make.listdecoration" />
		<xsl:text> </xsl:text>
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="refentry">
	
	</xsl:template>
	
	<xsl:template name="make.listdecoration">
		<xsl:for-each select="ancestor-or-self::itemizedlist|ancestor-or-self::orderedlist">
			<xsl:choose>
				<xsl:when test="local-name(.)='itemizedlist'">
					<xsl:text>*</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>#</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template name="make.title">
		<xsl:variable name="level">
			<xsl:value-of select="count(ancestor-or-self::*)"/>
		</xsl:variable>
		
		<xsl:variable name="title">
			<xsl:choose>
				<xsl:when test="bookinfo/title">
					<xsl:value-of select="normalize-space(bookinfo/title)"/>
				</xsl:when>
				<xsl:when test="articleinfo/title">
					<xsl:value-of select="normalize-space(articleinfo/title)"/>
				</xsl:when>
				<xsl:when test="partinfo/title">
					<xsl:value-of select="normalize-space(partinfo/title)"/>
				</xsl:when>
				<xsl:when test="chapterinfo/title">
					<xsl:value-of select="normalize-space(chapterinfo/title)"/>
				</xsl:when>
				<xsl:when test="sectioninfo/title">
					<xsl:value-of select="normalize-space(sectioneinfo/title)"/>
				</xsl:when>
				<xsl:when test="appendixinfo/title">
					<xsl:value-of select="normalize-space(appendixinfo/title)"/>
				</xsl:when>
				<xsl:when test="prefaceinfo/title">
					<xsl:value-of select="normalize-space(prefaceinfo/title)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="title"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:text>
</xsl:text>
		<xsl:choose>
			<xsl:when test="$level&lt;7">
				<xsl:text>h</xsl:text>
				<xsl:value-of select="$level"/>
				<xsl:text>. </xsl:text>
				<xsl:value-of select="$title"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>*</xsl:text>
				<xsl:value-of select="$title"/>
				<xsl:text>*</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:text>
</xsl:text>
	</xsl:template>
</xsl:stylesheet>
