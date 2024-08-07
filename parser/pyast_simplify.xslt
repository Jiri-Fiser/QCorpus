<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:py="http:/ki.ujep.cz/ns/py_ast"
                xmlns="http:/ki.ujep.cz/ns/qc_ast">
  <xsl:output method="xml" indent="yes"/>

  <xsl:template match="py:ctx"/>
  <xsl:template match="py:type_ignores"/>

  <xsl:template match="@*|*|text()">
    <xsl:copy>
      <xsl:apply-templates select="@*|*|text()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="py:Attribute">
    <xsl:element name="py:Attribute">
      <xsl:attribute name="name"><xsl:value-of select="@attr"/></xsl:attribute>
      <xsl:attribute name="longname"><xsl:apply-templates select="py:value" mode="attr"/>.<xsl:value-of select="@attr"/></xsl:attribute>
      <xsl:apply-templates select="*"/>
    </xsl:element>
  </xsl:template>


  <xsl:template match="py:value" mode="attr"><xsl:apply-templates select="py:Attribute|py:Name|py:Call" mode="attr"/></xsl:template>
  <xsl:template match="py:Attribute" mode="attr"><xsl:apply-templates select="py:value" mode="attr"/>.<xsl:value-of select="@attr"/></xsl:template>
  <xsl:template match="py:Name" mode="attr"><xsl:value-of select="@id"/></xsl:template>
  <xsl:template match="py:Call" mode="attr">#</xsl:template>


</xsl:stylesheet>