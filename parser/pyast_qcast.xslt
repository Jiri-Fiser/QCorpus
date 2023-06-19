<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:py="http:/ki.ujep.cz/ns/py_ast"
                xmlns:qc="http:/ki.ujep.cz/ns/qc_ast"
                xmlns="http:/ki.ujep.cz/ns/qc_ast">
  <xsl:output method="xml" indent="yes"/>

  <xsl:template match="py:Assign">
     <command type="assignment"><xsl:apply-templates/></command>
  </xsl:template>

  <xsl:template match="py:AnnAssign">
        <command type="assignment"><xsl:apply-templates/></command>
  </xsl:template>

  <xsl:template match="py:Assign/py:targets|py:AnnAssign/py:target">
    <left><xsl:apply-templates/></left>
  </xsl:template>

  <xsl:template match="py:Assign/py:value|py:AnnAssign/py:value">
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

  <xsl:template match="py:Expr"> <!-- statement formed by expression -->
    <statement type="expression">
      <xsl:apply-templates select="py:value/*"/>
    </statement>
  </xsl:template>

  <xsl:template match="py:Await">
    <coroutine_suspend type="await">
        <xsl:apply-templates select="py:value/*"/>
    </coroutine_suspend>
  </xsl:template>

  <xsl:template match="py:Yield">
    <coroutine_suspend type="yield">
        <xsl:apply-templates select="py:value/*"/>
    </coroutine_suspend>
  </xsl:template>

  <xsl:template match="py:YieldFrom">
    <coroutine_suspend type="yield_from">
        <xsl:apply-templates select="py:value/*"/>
    </coroutine_suspend>
  </xsl:template>

  <xsl:template match="py:Call[py:func/py:Name]"> <!-- call of named function-->
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

  <xsl:template match="py:Call"> <!-- call of anonymous (ad hoc evaluated function) -->
    <call complex="true">
      <function>
        <xsl:apply-templates select="py:func/*"/>
      </function>
      <arguments>
        <xsl:call-template name="call_args"/>
      </arguments>
    </call>
  </xsl:template>

  <xsl:template match="py:For|py:AsyncFor">
    <loop type="foreach">
      <xsl:if test="self::py:AsyncFor">
        <xsl:attribute name="async">True</xsl:attribute>
      </xsl:if>
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
          <xsl:apply-templates select="py:exc/*"/>
      </xsl:if>
      <xsl:apply-templates select="py:cause"/>
    </statement>
  </xsl:template>

  <xsl:template match="py:cause"> <!-- optional `from` clause of `raise`-->
    <cause>
      <xsl:apply-templates/>
    </cause>
  </xsl:template>

  <xsl:template match="py:Delete">
    <statement type="delete">
      <xsl:apply-templates select="py:targets/*"/>
    </statement>
  </xsl:template>

  <xsl:template match="py:Assert">
    <statement type="assert">
      <test>
        <xsl:apply-templates select="py:test/*"/>
      </test>
      <message>
         <xsl:apply-templates select="py:msg/*"/>
      </message>
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

  <xsl:template match="py:FunctionDef|py:AsyncFunctionDef">
    <function name="{@name}">
      <xsl:if test="self::py:AsyncFunctionDef">
        <xsl:attribute name="async">True</xsl:attribute>
      </xsl:if>
      <xsl:call-template name="fparam"/>
      <block>
        <xsl:apply-templates select="py:body/*"/>
      </block>
      <xsl:if test="py:decorator_list/*">
        <xsl:apply-templates select="py:decorator_list"/>
      </xsl:if>
    </function>
  </xsl:template>

  <xsl:template match="py:Lambda">
    <lambda>
      <xsl:call-template name="fparam"/>
      <body>
        <xsl:apply-templates select="py:body/*"/>
      </body>
    </lambda>
  </xsl:template>

  <xsl:template name="fparam">
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
  </xsl:template>
  
  <xsl:template match="py:ImportFrom">
    <import from="{@module}" which="variable|class|function">
      <!-- the kind of imported entity is not derivable-->
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
          <xsl:when test="self::py:ListComp">list</xsl:when>
          <xsl:when test="self::py:SetComp">set</xsl:when>
          <xsl:when test="self::py:DictComp">dictionary</xsl:when>
          <xsl:when test="self::py:GeneratorExp">iterable</xsl:when>
        </xsl:choose>
      </xsl:attribute>
        <xsl:choose>
          <xsl:when test="py:elt">
            <element>
              <xsl:apply-templates select="py:elt/*"/>
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

  <xsl:template match="py:ClassDef">
    <class name="{@name}">
      <xsl:for-each select="py:bases//py:Name">
       <base><xsl:value-of select="@id"/></base>
      </xsl:for-each>
      <fields>
        <xsl:for-each select="py:body/py:Assign|py:body/py:AnnAssign">
          <field type="class" visibility="public">
            <xsl:apply-templates select="."/>
          </field>
        </xsl:for-each>
      </fields>
      <methods>
        <xsl:for-each select="py:body/py:FunctionDef">
          <method visibility="public">
            <xsl:choose>
              <xsl:when test="py:decorator_list//py:Name[@id='staticmethod']">
                <xsl:attribute name="type">static</xsl:attribute>
              </xsl:when>
              <xsl:when test="py:decorator_list//py:Name[@id='classmethod']">
                <xsl:attribute name="type">class</xsl:attribute>
              </xsl:when>
              <xsl:otherwise>
                <xsl:attribute name="type">instance</xsl:attribute>
              </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
              <xsl:when test="py:decorator_list//py:Name[@id='property']">
                <xsl:attribute name="property">getter</xsl:attribute>
              </xsl:when>
            </xsl:choose>
            <xsl:apply-templates select="."/>
          </method>
        </xsl:for-each>
      </methods>
    </class>
  </xsl:template>

  <xsl:template match="py:With|py:AsyncWith">
    <context type="with">
      <xsl:if test="self::py:AsyncWith">
        <xsl:attribute name="async">True</xsl:attribute>
      </xsl:if>
      <xsl:apply-templates select="py:items/py:withitem"/>
      <block>
        <xsl:apply-templates select="py:body/*"/>
      </block>
    </context>
  </xsl:template>

  <xsl:template match="py:withitem">
    <xsl:choose>
      <xsl:when test="py:optional_vars">
        <declaration type="context_manager" definition="True">
          <xsl:choose>
            <xsl:when test="py:optional_vars/qc:expression/py:Name/@id">
              <xsl:attribute name="names">
                <xsl:value-of select="py:optional_vars/qc:expression/py:Name/@id"/>
              </xsl:attribute>
            </xsl:when>
            <xsl:when test="py:optional_vars/qc:expression/py:Tuple">
              <xsl:attribute name="names">
                <xsl:apply-templates select="py:optional_vars/qc:expression/py:Tuple/py:elts" mode="compact_tuple"/>
              </xsl:attribute>
            </xsl:when>
          </xsl:choose>
          <value>
            <xsl:apply-templates select="py:context_expr/*"/>
          </value>
        </declaration>
      </xsl:when>
      <xsl:otherwise>
        <value>
          <xsl:apply-templates select="py:context_expr/*"/>
        </value>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="py:Global|py:Nonlocal"> <!-- scope declarations-->
    <declaration definition="False">
      <xsl:attribute name="type">
        <xsl:choose>
          <xsl:when test="self::py:Global">global</xsl:when>
          <xsl:when test="self::py:Nonlocal">nonlocal</xsl:when>
        </xsl:choose>
      </xsl:attribute>
      <xsl:attribute name="names"><xsl:value-of select="py:names"/></xsl:attribute>
    </declaration>
  </xsl:template>

  <xsl:template match="py:Try|py:TryStar">
    <try>
      <xsl:if test="self::py:TryStar"> <!-- try blocks for exceptions groups-->
        <xsl:attribute name="group">True</xsl:attribute>
      </xsl:if>
      <block>
        <xsl:apply-templates select="py:body/*"/>
      </block>
      <xsl:apply-templates select="py:handlers/*"/>
      <xsl:apply-templates select="py:finalbody"/>
    </try>
  </xsl:template>

  <xsl:template match="py:ExceptHandler">
    <handler>
      <xsl:choose>
        <xsl:when test="py:type/qc:expression/py:Name/@id">
          <xsl:attribute name="exception"><xsl:value-of select="py:type/qc:expression/py:Name/@id"/></xsl:attribute>
        </xsl:when>
        <xsl:when test="py:type/qc:expression/py:Tuple">
          <xsl:attribute name="exception">
            <xsl:apply-templates select="py:type/qc:expression/py:Tuple/py:elts" mode="compact_tuple"/>
          </xsl:attribute>
        </xsl:when>
      </xsl:choose>

      <xsl:if test="@name">
          <declaration definition="True" type="exception_handler" names="{@name}"/>
      </xsl:if>
      <block>
        <xsl:apply-templates select="py:body/*"/>
      </block>
    </handler>
  </xsl:template>

  <xsl:template match="py:finalbody">
    <finally>
      <block>
        <xsl:apply-templates/>
      </block>
    </finally>
  </xsl:template>

  <xsl:template match="py:Match">
    <match type="pattern">
      <value>
        <xsl:apply-templates select="py:subject/*"/>
      </value>
      <xsl:apply-templates select="py:cases/*"/>
    </match>
  </xsl:template>

  <xsl:template match="py:match_case">
    <case>
      <pattern>
        <xsl:apply-templates select="py:pattern/*"/> <!-- patterns are not translated to qc semantics-->
      </pattern>
      <xsl:if test="py:guard">
          <guard>
            <xsl:apply-templates select="py:guard/*"/>
          </guard>
      </xsl:if>
      <block>
        <xsl:apply-templates select="py:body/*"/>
      </block>
    </case>
  </xsl:template>

  <xsl:template match="py:NamedExpr"> <!-- walrus operator-->
    <operator arity="2" symbol="assign" side_effect="true">
      <xsl:apply-templates select="py:target/*"/>
      <xsl:apply-templates select="py:value/*"/>
    </operator>
  </xsl:template>

  <xsl:template match="@*|*|text()"> <!-- copying of all attributes, elements and text nodes -->
    <xsl:copy>
      <xsl:apply-templates select="@*|*|text()"/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
