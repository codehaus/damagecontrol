<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                >

<!-- 
http://www.biglist.com/lists/xsl-list/archives/200302/msg00504.html 
-->
<xsl:template match="Array">
  <stats>
    <x-axis label="dc_creation_time">
      <y-axis label="duration"/>
      <y-axis label="status"/>
    </x-axis>
    <xsl:for-each select="DamageControl-Build">
      <x>
        <xsl:attribute name="value">
          <xsl:value-of select="dc_creation_time/Time"/>
        </xsl:attribute>
        <y>
          <xsl:attribute name="value">
            <xsl:value-of select="duration/Fixnum"/>
          </xsl:attribute>
        </y>      
        <y>
          <xsl:attribute name="value">
            <xsl:value-of select="status/String"/>
          </xsl:attribute>
        </y>      
      </x>      
    </xsl:for-each>
  </stats>
</xsl:template>
</xsl:stylesheet>

