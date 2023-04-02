<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:py="http:/ki.ujep.cz/ns/py_ast"
                xmlns="http:/ki.ujep.cz/ns/qc_ast" xmlns:xslt="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" indent="yes"/>

  <xsl:template match="py:Assign">
     <command type="assignment"><xsl:apply-templates/></command>
  </xsl:template>

  <xsl:template match="py:Assign/py:targets">
    <left><xsl:apply-templates/></left>
  </xsl:template>

  <xsl:template match="py:Assign/py:value">
    <right><xsl:apply-templates/></right>
  </xsl:template>

  <xsl:template match="py:Module">
    <module>
      <xsl:apply-templates select="py:body/*"/>
    </module>
  </xsl:template>

  <xsl:template match="py:ast">
      <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="py:Name">
    <variable name="{@id}"/>
  </xsl:template>

  <xsl:template match="py:BinOp">
    <operator arity="2" symbol="{py:operator/@symbol}">
      <xsl:apply-templates select="py:left/*"/>
      <xsl:apply-templates select="py:right/*"/>
    </operator>
  </xsl:template>

   <xsl:template match="py:BoolOp">
    <operator arity="2" symbol="{py:operator/@symbol}" non_strict="true">
      <xsl:apply-templates select="py:values/*"/>
    </operator>
  </xsl:template>

    <xsl:template match="py:Compare[count(py:ops/*) = 1]">
    <operator arity="2" symbol="{py:ops/py:operator/@symbol}">
      <xsl:apply-templates select="py:left/*"/>
      <xsl:apply-templates select="py:comparators/*"/>
    </operator>
  </xsl:template>

    <xsl:template match="py:UnaryOp">
    <operator arity="1" symbol="{py:operator/@symbol}">
      <xsl:apply-templates select="py:operand/*"/>
    </operator>
  </xsl:template>

  <xsl:template match="py:Subscript">
    <indexing>
      <xsl:attribute name="dimensions">
        <xsl:choose>
          <xsl:when test="py:slice/py:Tuple"><xsl:value-of select="count(py:slice/py:Tuple/py:elts/*)"/></xsl:when>
          <xsl:otherwise>1</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <container>
        <xsl:apply-templates select="py:value/*"/>
      </container>
      <index>
        <xsl:apply-templates select="py:slice/*"/>
      </index>
    </indexing>
  </xsl:template>
  
  <xsl:template match="py:Slice">
    <range>
      <start>
        <xsl:choose>
          <xsl:when test="py:lower"><xsl:apply-templates select="py:lower/*"/></xsl:when>
          <xsl:otherwise><xsl:attribute name="implicit">0</xsl:attribute></xsl:otherwise>
        </xsl:choose>
      </start>
      <end>
        <xsl:choose>
          <xsl:when test="py:upper"><xsl:apply-templates select="py:upper/*"/></xsl:when>
          <xsl:otherwise><xsl:attribute name="implicit">size-1</xsl:attribute></xsl:otherwise>
        </xsl:choose>
      </end>
      <step>
        <xsl:choose>
          <xsl:when test="py:step"><xsl:apply-templates select="py:step/*"/></xsl:when>
          <xsl:otherwise><xsl:attribute name="implicit">1</xsl:attribute></xsl:otherwise>
        </xsl:choose>
      </step>
    </range>
  </xsl:template>

  <xsl:template match="py:Constant">
    <literal>
      <xsl:apply-templates select="@*"/>
    </literal>
  </xsl:template>

  <xsl:template match="py:List">
    <collection type="list">
      <xsl:apply-templates select="py:elts/*"/>
    </collection>
  </xsl:template>

  <xsl:template match="py:Tuple">
    <collection type="tuple">
      <xsl:apply-templates select="py:elts/*"/>
    </collection>
  </xsl:template>

  <xsl:template match="py:Set">
    <collection type="set">
      <xsl:apply-templates select="py:elts/*"/>
    </collection>
  </xsl:template>

  <xsl:template match="py:Dict">
    <collection type="dictionary">
      <xsl:for-each select="py:keys/*">
        <xsl:variable name="pos" select="position()"/>
        <pair>
          <xsl:apply-templates select="."/>
          <xsl:apply-templates select="../../py:values/*[$pos]"/>
        </pair>
      </xsl:for-each>
    </collection>
  </xsl:template>

  <xsl:template match="py:Expr">
    <statement type="expression">
      <xsl:apply-templates select="py:value/*"/>
    </statement>
  </xsl:template>

  <xsl:template match="py:Call[py:func/py:Name]">
    <call name="{py:func/py:Name/@id}" complex="false">
      <arguments>
        <xsl:call-template name="call_args"/>
      </arguments>
    </call>
  </xsl:template>

  <xsl:template name="call_args">
    <xsl:for-each select="py:args/*">
      <xsl:choose>
        <xsl:when test="self::py:Starred">
          <argument type="positional" unpacking="true"><xsl:apply-templates select="py:value/*"/></argument>
        </xsl:when>
        <xsl:otherwise>
          <argument type="positional" unpacking="false"><xsl:apply-templates select="."/></argument>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
    <xsl:for-each select="py:keywords/*">
      <xsl:choose>
        <xsl:when test="@arg">
          <argument type="named" name="{@arg}" unpacking="false"><xsl:apply-templates select="py:value/*"/></argument>
        </xsl:when>
        <xsl:otherwise>
          <argument type="named" unpacking="true"><xsl:apply-templates select="py:value/*"/></argument>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="py:Call">
    <call complex="true">
      <function>
        <xsl:apply-templates select="py:func/*"/>
      </function>
      <arguments>
        <xsl:call-template name="call_args"/>
      </arguments>
    </call>
  </xsl:template>

  <xsl:template match="@*|*|text()">
    <xsl:copy>
      <xsl:apply-templates select="@*|*|text()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="py:For">
    <loop type="foreach">
      <xsl:choose>
        <xsl:when test="py:target/expression/py:Name/@id">
          <xsl:attribute name="target">
            <xsl:value-of select="py:target/expression/py:Name/@id"/>
          </xsl:attribute>
        </xsl:when>
        <xsl:when test="py:target/expression/py:Tuple">
          <xsl:attribute name="targets">
            <xsl:apply-templates select="py:target/expression/py:Tuple/py:elts" mode="compact_tuple"/>
          </xsl:attribute>
        </xsl:when>
      </xsl:choose>
      <iterable>
        <xsl:apply-templates select="py:iter/*"/>
      </iterable>
      <block>
        <xsl:apply-templates select="py:body/*"/>
      </block>
    </loop>
  </xsl:template>

  <xsl:template match="py:elts" mode="compact_tuple">
    <xsl:for-each select="py:Name"><xsl:if test="position() > 1">,</xsl:if><xsl:value-of select="@id"/></xsl:for-each>
  </xsl:template>

  <xsl:template match="py:Pass">
    <statement type="empty"/>
  </xsl:template>

  <xsl:template match="py:Break">
    <statement  type="break" jump="true"/>
  </xsl:template>

  <xsl:template match="py:Continue">
    <statement  type="continue" jump="true"/>
  </xsl:template>

  <xsl:template match="py:Return">
    <statement type="return">
       <xsl:apply-templates select="py:value/*"/>
    </statement>
  </xsl:template>

    <xsl:template match="py:Raise">
    <statement type="throw">
      <xsl:if test="py:exc">
        <exception>
          <xsl:apply-templates select="py:exc/*"/>
        </exception>
      </xsl:if>
      <xsl:apply-templates select="py:cause"/>
    </statement>
  </xsl:template>

  <xsl:template match="py:Delete">
    <statement type="delete">
      <xsl:apply-templates select="py:targets/*"/>
    </statement>
  </xsl:template>

  <xsl:template match="py:While">
    <loop type="while">
      <condition>
        <xsl:apply-templates select="py:test/*"/>
      </condition>
      <block>
        <xsl:apply-templates select="py:body/*"/>
      </block>
    </loop>
  </xsl:template>

  <xsl:template match="py:If">
      <if>
        <condition>
          <xsl:apply-templates select="py:test/*"/>
        </condition>
        <then>
          <xsl:apply-templates select="py:body/*"/>
        </then>
        <else>
          <xsl:apply-templates select="py:orelse/*"/>
        </else>
      </if>
  </xsl:template>

  <xsl:template match="py:FunctionDef">
    <function name="{@name}">
      <parameters>
        <xsl:for-each select="py:args/py:arguments/py:posonlyargs/py:arg">
          <xsl:variable name="argpos" select="count(../../py:args)+last()-position()+1"/>
          <parameter name="{@arg}" positional="true" named="false">
            <xsl:if test="count(../../py:defaults/*)>=$argpos">
              <xsl:apply-templates select="../../py:defaults/*[last()-$argpos]"/>
            </xsl:if>
          </parameter>
        </xsl:for-each>
        <xsl:for-each select="py:args/py:arguments/py:args/py:arg">
          <xsl:variable name="argpos" select="last()-position()"/>
          <parameter name="{@arg}" positional="true" named="true">
            <xsl:if test="count(../../py:defaults/*)>=$argpos">
              <xsl:apply-templates select="../../py:defaults/*[last()-$argpos]"/>
            </xsl:if>
          </parameter>
        </xsl:for-each>
        <xsl:for-each select="py:args/py:arguments/py:kwonlyargs/py:arg">
          <xsl:variable name="argpos"  select="position()"/>
          <parameter name="{@arg}" positional="false" named="true">
            <xsl:if test="name(../../py:kw_defaults/*[position()=$argpos])!='py:empty'">
              <xsl:apply-templates select="../../py:kw_defaults/*[position()=$argpos]"/>
            </xsl:if>
          </parameter>
        </xsl:for-each>
      </parameters>
      <block>
        <xsl:apply-templates select="py:body/*"/>
      </block>
      <xsl:if test="py:decorator_list/*">
        <xsl:apply-templates select="py:decorator_list"/>
      </xsl:if>
    </function>
  </xsl:template>
  
  <xsl:template match="py:ImportFrom">
    <import from="{@module}" which="variable|class|function">
      <xsl:for-each select="py:names">
          <xsl:choose>
            <xsl:when test="py:alias/@asname">
              <name original_name="{py:alias/@name}">
                <xsl:value-of select="py:alias/@asname"/>
              </name>
            </xsl:when>
            <xsl:otherwise>
              <name>
                <xsl:value-of select="py:alias/@name"/>
              </name>
            </xsl:otherwise>
          </xsl:choose>
      </xsl:for-each>
    </import>
  </xsl:template>

  <xsl:template match="py:Import">
    <import which="module">
      <xsl:for-each select="py:names">
          <xsl:choose>
            <xsl:when test="py:alias/@asname">
              <name original_name="{py:alias/@name}">
                <xsl:value-of select="py:alias/@asname"/>
              </name>
            </xsl:when>
            <xsl:otherwise>
              <name>
                <xsl:value-of select="py:alias/@name"/>
              </name>
            </xsl:otherwise>
          </xsl:choose>
      </xsl:for-each>
    </import>
  </xsl:template>

  <xsl:template match="py:ListComp|py:SetComp|py:GeneratorExp|py:DictComp">
    <comprehension>
      <xsl:attribute name="product">
        <xsl:choose>
          <xsl:when test="name(.)='py:ListComp'">list</xsl:when>
          <xsl:when test="name(.)='py:SetComp'">set</xsl:when>
          <xsl:when test="name(.)='py:DictComp'">dictionary</xsl:when>
          <xsl:when test="name(.)='py:GeneratorExp'">iterable</xsl:when>
        </xsl:choose>
      </xsl:attribute>
        <xsl:choose>
          <xsl:when test="py:elt">
            <element>
              <xslt:apply-templates select="py:elt/*"/>
            </element>
          </xsl:when>
          <xsl:when test="py:key">
            <pair>
              <xsl:apply-templates select="py:key/*"/>
              <xsl:apply-templates select="py:value/*"/>
            </pair>
          </xsl:when>
        </xsl:choose>
      <xsl:for-each select="py:generators/py:comprehension">
        <generator>
          <xsl:choose>
            <xsl:when test="py:target/py:Name/@id">
              <xsl:attribute name="target">
                <xsl:value-of select="py:target/py:Name/@id"/>
              </xsl:attribute>
            </xsl:when>
            <xsl:when test="py:target/py:Tuple">
              <xsl:attribute name="targets">
                <xsl:apply-templates select="py:target/py:Tuple/py:elts" mode="compact_tuple"/>
              </xsl:attribute>
            </xsl:when>
          </xsl:choose>
          <iterable>
            <xsl:apply-templates select="py:iter/*"/>
          </iterable>
          <xsl:for-each select="py:ifs/*">
            <condition>
              <xsl:apply-templates select="."/>
            </condition>
          </xsl:for-each>
        </generator>
      </xsl:for-each>
    </comprehension>
  </xsl:template>
</xsl:stylesheet>
