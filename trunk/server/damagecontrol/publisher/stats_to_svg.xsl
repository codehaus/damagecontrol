<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:date="http://exslt.org/dates-and-times"
                >

<!-- 
Some nice graphs we can use for inspiration:

http://aeditor.rubyforge.org/graphs.html
http://www.jbrowse.com/text/rws.shtml
http://leo.cuckoo.org/projects/SVG-TT-Graph/examples/
http://ploticus.sourceforge.net/

Here is some arithmetic!
http://cvs.apache.org/viewcvs.cgi/xml-batik/contrib/charts/
-->

<xsl:variable name="width">500</xsl:variable>
<xsl:variable name="height">200</xsl:variable>

<xsl:variable name="margin">10</xsl:variable>
<xsl:variable name="labelY">50</xsl:variable>
<xsl:variable name="labelX">20</xsl:variable>

<xsl:variable name="chartHeight" select="$height - (2 * $margin) - $labelX"/>
<xsl:variable name="chartWidth"  select="$width  - (4 * $margin) - $labelY"/>

<xsl:variable name="verticalRangeMax">
  <xsl:for-each select="//y/@value">
    <xsl:sort order="descending" data-type="number" select="text()"/>
    <xsl:if test="position() = 1"><xsl:value-of select="."/></xsl:if>
  </xsl:for-each>
</xsl:variable>

<xsl:variable name="horizontalRangeMax">
  <xsl:for-each select="//x/@value">
    <xsl:sort order="descending" data-type="number" select="date:seconds(.)"/>
    <xsl:if test="position() = 1"><xsl:value-of select="date:seconds(.)"/></xsl:if>
  </xsl:for-each>
</xsl:variable>

<xsl:variable name="verticalScale">
  <xsl:value-of select="$chartHeight div $verticalRangeMax"/>
</xsl:variable>

<xsl:variable name="horizontalScale">
  <xsl:value-of select="$chartWidth div $horizontalRangeMax"/>
</xsl:variable>

<xsl:template name="verticalGridlines">
  <xsl:param name="value">0</xsl:param>
  <xsl:param name="step"/>

	<line
	  id="verticalGridline_{$value}"
	  x1="{$value * $horizontalScale}"
	  y1="-2"
	  x2="{$value * $horizontalScale}"
	  y2="{$verticalRangeMax * $verticalScale}"
	  style="fill:none;stroke:black;stroke-width:1"/>

	<text
	  transform="matrix(1 0 0 -1 0 -{$labelX})"
	  x="{$value * $horizontalScale}"
	  y="0"
	  style="text-anchor:middle;font-size:12;fill:black">
            <xsl:value-of select="//meta/axis/x/value[position() = $value + 1]"/>
	</text>

  <xsl:if test="$value + $step &lt; $horizontalRangeMax">
    <xsl:call-template name="verticalGridlines">
      <xsl:with-param name="value"><xsl:value-of select="$value + $step"/></xsl:with-param>
      <xsl:with-param name="step"><xsl:value-of select="$step"/></xsl:with-param>
    </xsl:call-template>
  </xsl:if>
</xsl:template>

<xsl:template match="stats">
  <svg>
    <foo BAR="{$horizontalRangeMax}"></foo>
    <xsl:call-template name="verticalGridlines">
      <xsl:with-param name="value">0</xsl:with-param>
      <xsl:with-param name="step">1</xsl:with-param>
    </xsl:call-template>

    <!-- draw path -->
    <g transform="matrix(1 0 0 -1 {$margin + $labelY} {$height - ($margin + $labelX)})" style="fill:none;stroke:blue;stroke-width:4.0;font-size:8:text-anchor:end">
      <line x1="0" y1="0" x2="0" y2="{$verticalRangeMax}" style="fill:none;stroke:black;stroke-width:1"/>

      <xsl:variable name="path">
        <xsl:text>M 0 0 </xsl:text>
        <xsl:for-each select="x">
          <xsl:text>L</xsl:text>
          <xsl:value-of select="position()*50"/>
          <xsl:text> </xsl:text>
          <xsl:value-of select="y[$yset]/@value*50"/>
          <xsl:text> </xsl:text>
        </xsl:for-each>
      </xsl:variable>
      <path>
        <xsl:attribute name="d">
          <xsl:value-of select="($path)"/>
        </xsl:attribute>
      </path>
    </g>

    <!-- draw dots -->
    <g transform="translate(20,200)" style="fill:none;stroke:blue;stroke-width:4.0;font-size:8:text-anchor:end">
      <xsl:for-each select="x">
        <xsl:variable name="dot">
          <xsl:text>M</xsl:text>
          <xsl:value-of select="position()*50+4"/>
          <xsl:text> </xsl:text>
          <xsl:value-of select="y[$yset]/@value*50"/>
          <xsl:text> l-4 -4 l-4 4 l 4 4z</xsl:text>
        </xsl:variable>
        <path fill="#000000" stroke="#000000" >
          <xsl:attribute name="d">
            <xsl:value-of select="($dot)"/>
          </xsl:attribute>
        </path>
      </xsl:for-each>
    </g>

  </svg>
</xsl:template>
</xsl:stylesheet>

