<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:date="http://exslt.org/dates-and-times"
                >

<!-- 
http://www.biglist.com/lists/xsl-list/archives/200302/msg00504.html 
-->
<xsl:template match="stats">
  <svg>

    <xsl:variable name="width">500</xsl:variable>
    <xsl:variable name="height">200</xsl:variable>
    <xsl:variable name="count">7</xsl:variable>
    <xsl:variable name="maxval">7</xsl:variable>

    <!-- find max value -->
    <!--xsl:variable name="max">
      <xsl:value-of select="math:max(date:seconds(end_time/Time) - date:seconds(start_time/Time))" />
    </xsl:variable-->

    <!-- draw path -->
    <g transform="translate(20,200)" style="fill:none;stroke:blue;stroke-width:4.0;font-size:8:text-anchor:end">
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

