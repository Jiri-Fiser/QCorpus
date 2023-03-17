<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:py="http:/ki.ujep.cz/ns/py_ast"
                xmlns:qc="http:/ki.ujep.cz/ns/qc_ast">
  <xsl:output method="xml" indent="yes"/>

  <xsl:template match="py:Assign">
     <qc:command type="assignment"><xsl:apply-templates/></qc:command>
  </xsl:template>

  <xsl:template match="py:Assign/py:targets">
    <qc:left><xsl:apply-templates/></qc:left>
  </xsl:template>

  <xsl:template match="py:Assign/py:value">
    <qc:right><xsl:apply-templates/></qc:right>
  </xsl:template>

  <xsl:template match="py:Module">
    <qc:module>
      <xsl:apply-templates select="py:body/*"/>
    </qc:module>
  </xsl:template>

  <xsl:template match="py:ast">
      <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="py:Name">
    <qc:variable name="{@id}"/>
  </xsl:template>

  <xsl:template match="py:BinOp">
    <qc:operator arity="2" symbol="{py:operator/@symbol}">
      <xsl:apply-templates select="py:left/*"/>
      <xsl:apply-templates select="py:right/*"/>
    </qc:operator>
  </xsl:template>

   <xsl:template match="py:BoolOp">
    <qc:operator arity="2" symbol="{py:operator/@symbol}" non_strict="true">
      <xsl:apply-templates select="py:values/*"/>
    </qc:operator>
  </xsl:template>

    <xsl:template match="py:Compare[count(py:ops/*) = 1]">
    <qc:operator arity="2" symbol="{py:ops/py:operator/@symbol}">
      <xsl:apply-templates select="py:left/*"/>
      <xsl:apply-templates select="py:comparators/*"/>
    </qc:operator>
  </xsl:template>

    <xsl:template match="py:UnaryOp">
    <qc:operator arity="1" symbol="{py:operator/@symbol}">
      <xsl:apply-templates select="py:operand/*"/>
    </qc:operator>
  </xsl:template>

  <xsl:template match="py:Constant">
    <qc:literal>
      <xsl:apply-templates select="@*"/>
    </qc:literal>
  </xsl:template>

  <xsl:template match="py:List">
    <qc:collection type="list">
      <xsl:apply-templates select="py:elts/*"/>
    </qc:collection>
  </xsl:template>

  <xsl:template match="py:Tuple">
    <qc:collection type="tuple">
      <xsl:apply-templates select="py:elts/*"/>
    </qc:collection>
  </xsl:template>

  <xsl:template match="py:Set">
    <qc:collection type="set">
      <xsl:apply-templates select="py:elts/*"/>
    </qc:collection>
  </xsl:template>

  <xsl:template match="py:Expr">
    <qc:statement type="expression">
      <xsl:apply-templates select="py:value/*"/>
    </qc:statement>
  </xsl:template>

  <xsl:template match="py:Call[py:func/py:Name]">
    <qc:call name="{py:func/py:Name/@id}" complex="false">
      <qc:args>
        <xsl:call-template name="call_args"/>
      </qc:args>
    </qc:call>
  </xsl:template>

  <xsl:template name="call_args">
    <xsl:for-each select="py:args/*">
      <xsl:choose>
        <xsl:when test="self::py:Starred">
          <qc:argument type="positional" unpacking="true"><xsl:apply-templates select="py:value/*"/></qc:argument>
        </xsl:when>
        <xsl:otherwise>
          <qc:argument type="positional" unpacking="false"><xsl:apply-templates select="."/></qc:argument>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
    <xsl:for-each select="py:keywords/*">
      <xsl:choose>
        <xsl:when test="@arg">
          <qc:argument type="named" name="{@arg}" unpacking="false"><xsl:apply-templates select="py:value/*"/></qc:argument>
        </xsl:when>
        <xsl:otherwise>
          <qc:argument type="named" unpacking="true"><xsl:apply-templates select="py:value/*"/></qc:argument>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="py:Call">
    <qc:call complex="true">
      <qc:function>
        <xsl:apply-templates select="py:func/*"/>
      </qc:function>
      <qc:args>
        <xsl:call-template name="call_args"/>
      </qc:args>
    </qc:call>
  </xsl:template>

  <xsl:template match="@*|*|text()">
    <xsl:copy>
      <xsl:apply-templates select="@*|*|text()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="py:For">
    <qc:loop type="foreach">
      <xsl:choose>
        <xsl:when test="py:target/qc:expression/py:Name/@id">
          <xsl:attribute name="target">
            <xsl:value-of select="py:target/qc:expression/py:Name/@id"/>
          </xsl:attribute>
        </xsl:when>
        <xsl:when test="py:target/qc:expression/py:Tuple">
          <xsl:attribute name="targets">
            <xsl:apply-templates select="py:target/qc:expression/py:Tuple/py:elts" mode="compact_tuple"/>
          </xsl:attribute>
        </xsl:when>
      </xsl:choose>
      <qc:iterable>
        <xsl:apply-templates select="py:iter/*"/>
      </qc:iterable>
      <qc:block>
        <xsl:apply-templates select="py:body/*"/>
      </qc:block>
    </qc:loop>
  </xsl:template>

  <xsl:template match="py:elts" mode="compact_tuple">
    <xsl:for-each select="py:Name"><xsl:if test="position() > 1">,</xsl:if><xsl:value-of select="@id"/></xsl:for-each>
  </xsl:template>

  <xsl:template match="py:Pass">
    <qc:statement type="empty"/>
  </xsl:template>

  <xsl:template match="py:Break">
    <qc:statement  type="break" jump="true"/>
  </xsl:template>

  <xsl:template match="py:Continue">
    <qc:statement  type="continue" jump="true"/>
  </xsl:template>

  <xsl:template match="py:While">
    <qc:loop type="while">
      <qc:condition>
        <xsl:apply-templates select="py:test/*"/>
      </qc:condition>
      <qc:block>
        <xsl:apply-templates select="py:body/*"/>
      </qc:block>
    </qc:loop>
  </xsl:template>

  <xsl:template match="py:If">
      <qc:if>
        <qc:condition>
          <xsl:apply-templates select="py:test/*"/>
        </qc:condition>
        <qc:then>
          <xsl:apply-templates select="py:body/*"/>
        </qc:then>
        <qc:else>
          <xsl:apply-templates select="py:orelse/*"/>
        </qc:else>
      </qc:if>
  </xsl:template>

  <xsl:template match="py:FunctionDef">
    <qc:function name="{@name}">
      <qc:parameters>
        <xsl:for-each select="py:args/py:arguments/py:posonlyargs/py:arg">
          <qc:parameter name="{@arg}" positional="true" named="false"/>
        </xsl:for-each>
        <xsl:for-each select="py:args/py:arguments/py:args/py:arg">
          <qc:parameter name="{@arg}" positional="true" named="true"/>
        </xsl:for-each>
        <xsl:for-each select="py:args/py:arguments/py:kwonlyargs/py:arg">
          <xsl:variable name="argpos"  select="position()"/>
          <qc:parameter name="{@arg}" positional="false" named="true">
            <xsl:if test="name(../../py:kw_defaults/*[position()=$argpos])!='py:empty'">
            <xsl:apply-templates select="../../py:kw_defaults/*[position()=$argpos]"/>
            </xsl:if>
          </qc:parameter>
        </xsl:for-each>
      </qc:parameters>
      <qc:block>
        <xsl:apply-templates select="py:body"/>
      </qc:block>
    </qc:function>
  </xsl:template>
  
  <xsl:template match="py:ImportFrom">
    <qc:import from="{@module}" which="variable|class|function">
      <xsl:for-each select="py:names">
          <xsl:choose>
            <xsl:when test="py:alias/@asname">
              <qc:name original_name="{py:alias/@name}">
                <xsl:value-of select="py:alias/@asname"/>
              </qc:name>
            </xsl:when>
            <xsl:otherwise>
              <qc:name>
                <xsl:value-of select="py:alias/@name"/>
              </qc:name>
            </xsl:otherwise>
          </xsl:choose>
      </xsl:for-each>
    </qc:import>
  </xsl:template>

  <xsl:template match="py:Import">
    <qc:import which="modules">
      <xsl:for-each select="py:names">
          <xsl:choose>
            <xsl:when test="py:alias/@asname">
              <qc:name original_name="{py:alias/@name}">
                <xsl:value-of select="py:alias/@asname"/>
              </qc:name>
            </xsl:when>
            <xsl:otherwise>
              <qc:name>
                <xsl:value-of select="py:alias/@name"/>
              </qc:name>
            </xsl:otherwise>
          </xsl:choose>
      </xsl:for-each>
    </qc:import>
  </xsl:template>
</xsl:stylesheet>
