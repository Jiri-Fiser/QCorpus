<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:py="http:/ki.ujep.cz/ns/py_ast"
                xmlns:qc="http:/ki.ujep.cz/ns/qc_ast">
  <xsl:output method="xml" indent="yes"/>

  <xsl:template match="py:Assign">
     <qc:Assignment><xsl:apply-templates/></qc:Assignment>
  </xsl:template>

  <xsl:template match="py:Assign/py:targets">
    <qc:left><xsl:apply-templates/></qc:left>
  </xsl:template>

  <xsl:template match="py:Assign/py:value">
    <qc:right><xsl:apply-templates/></qc:right>
  </xsl:template>

  <xsl:template match="py:Module">
    <xsl:apply-templates select="py:body/*"/>
  </xsl:template>

  <xsl:template match="py:ast">
    <qc:ast>
      <xsl:apply-templates/>
    </qc:ast>
  </xsl:template>

  <xsl:template match="py:Name">
    <qc:Variable identifier="{@id}"/>
  </xsl:template>

  <xsl:template match="py:BinOp">
    <qc:Operator arity="2" symbol="{py:operator/@symbol}">
      <xsl:apply-templates select="py:left/*"/>
      <xsl:apply-templates select="py:right/*"/>
    </qc:Operator>
  </xsl:template>

   <xsl:template match="py:BoolOp">
    <qc:Operator arity="2" symbol="{py:operator/@symbol}" non_strict="true">
      <xsl:apply-templates select="py:values/*"/>
    </qc:Operator>
  </xsl:template>

    <xsl:template match="py:Compare[count(py:ops/*) = 1]">
    <qc:Operator arity="2" symbol="{py:ops/py:operator/@symbol}">
      <xsl:apply-templates select="py:left/*"/>
      <xsl:apply-templates select="py:comparators/*"/>
    </qc:Operator>
  </xsl:template>

    <xsl:template match="py:UnaryOp">
    <qc:Operator arity="1" symbol="{py:operator/@symbol}">
      <xsl:apply-templates select="py:operand/*"/>
    </qc:Operator>
  </xsl:template>

  <xsl:template match="py:Constant">
    <qc:Literal>
      <xsl:apply-templates select="@*"/>
    </qc:Literal>
  </xsl:template>

  <xsl:template match="py:List">
    <qc:Collection type="list">
      <xsl:apply-templates select="py:elts/*"/>
    </qc:Collection>
  </xsl:template>

  <xsl:template match="py:Tuple">
    <qc:Collection type="tuple">
      <xsl:apply-templates select="py:elts/*"/>
    </qc:Collection>
  </xsl:template>

    <xsl:template match="py:Set">
    <qc:Collection type="set">
      <xsl:apply-templates select="py:elts/*"/>
    </qc:Collection>
  </xsl:template>

  <xsl:template match="py:Expr">
    <qc:SimpleStatement type="expression">
      <xsl:apply-templates select="py:value/*"/>
    </qc:SimpleStatement>
  </xsl:template>

  <xsl:template match="py:Call[py:func/py:Name]">
    <qc:Call name="{py:func/py:Name/@id}" complex="false">
      <qc:args>
        <xsl:call-template name="call_args"/>
      </qc:args>
    </qc:Call>
  </xsl:template>

  <xsl:template name="call_args">
    <xsl:for-each select="py:args/*">
      <xsl:choose>
        <xsl:when test="self::py:Starred">
          <qc:parameter type="positional" unpacking="true"><xsl:apply-templates select="py:value/*"/></qc:parameter>
        </xsl:when>
        <xsl:otherwise>
          <qc:parameter type="positional" unpacking="false"><xsl:apply-templates select="."/></qc:parameter>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
    <xsl:for-each select="py:keywords/*">
      <xsl:choose>
        <xsl:when test="@arg">
          <qc:parameter type="named" name="{@arg}" unpacking="false"><xsl:apply-templates select="py:value/*"/></qc:parameter>
        </xsl:when>
        <xsl:otherwise>
          <qc:parameter type="named" unpacking="true"><xsl:apply-templates select="py:value/*"/></qc:parameter>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="py:Call">
    <qc:Call complex="true">
      <qc:function>
        <xsl:apply-templates select="py:func/*"/>
      </qc:function>
      <qc:args>
        <xsl:call-template name="call_args"/>
      </qc:args>
    </qc:Call>
  </xsl:template>

  <xsl:template match="@*|*|text()">
    <xsl:copy>
      <xsl:apply-templates select="@*|*|text()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="py:For">
    <qc:Loop type="foreach">
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
      <qc:body>
        <xsl:apply-templates select="py:body/*"/>
      </qc:body>
    </qc:Loop>
  </xsl:template>

  <xsl:template match="py:elts" mode="compact_tuple">
    <xsl:for-each select="py:Name"><xsl:if test="position() > 1">,</xsl:if><xsl:value-of select="@id"/></xsl:for-each>
  </xsl:template>

  <xsl:template match="py:Pass">
    <qc:Empty_statement/>
  </xsl:template>

  <xsl:template match="py:Break">
    <qc:SimpleStatement  type="break" jump="true"/>
  </xsl:template>

  <xsl:template match="py:Continue">
    <qc:SimpleStatement  type="continue" jump="true"/>
  </xsl:template>

  <xsl:template match="py:While">
    <qc:Loop type="while">
      <qc:condition>
        <xsl:apply-templates select="py:test/*"/>
      </qc:condition>
      <qc:body>
        <xsl:apply-templates select="py:body/*"/>
      </qc:body>
    </qc:Loop>
  </xsl:template>

  <xsl:template match="py:If">
      <qc:If>
        <qc:condition>
          <xsl:apply-templates select="py:test/*"/>
        </qc:condition>
        <qc:then>
          <xsl:apply-templates select="py:body/*"/>
        </qc:then>
        <qc:else>
          <xsl:apply-templates select="py:orelse/*"/>
        </qc:else>
      </qc:If>
  </xsl:template>

  <xsl:template match="py:FunctionDef">
    <qc:FunctionDef name="{@name}">
      <qc:arguments>
        <xsl:for-each select="py:args/py:arguments/py:posonlyargs/py:arg">
          <qc:argument name="{@arg}" positional="true" named="false"/>
        </xsl:for-each>
        <xsl:for-each select="py:args/py:arguments/py:args/py:arg">
          <qc:argument name="{@arg}" positional="true" named="true"/>
        </xsl:for-each>
        <xsl:for-each select="py:args/py:arguments/py:kwonlyargs/py:arg">
          <xsl:variable name="argpos"  select="position()"/>
          <qc:argument name="{@arg}" positional="false" named="true">
            <xsl:if test="name(../../py:kw_defaults/*[position()=$argpos])!='py:empty'">
            <xsl:apply-templates select="../../py:kw_defaults/*[position()=$argpos]"/>
            </xsl:if>
          </qc:argument>
        </xsl:for-each>
      </qc:arguments>
      <qc:body>
        <xsl:apply-templates select="py:body"/>
      </qc:body>
    </qc:FunctionDef>
  </xsl:template>
  
  <xsl:template match="py:ImportFrom">
    <qc:import_names from="{@module}" which="variable|class|function">
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
    </qc:import_names>
  </xsl:template>

  <xsl:template match="py:Import">
    <qc:import_names which="modules">
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
    </qc:import_names>
  </xsl:template>
</xsl:stylesheet>
