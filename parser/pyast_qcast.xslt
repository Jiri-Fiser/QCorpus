<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:py="http:/ki.ujep.cz/ns/py_ast"
                xmlns:qc="http:/ki.ujep.cz/ns/qc_ast"
                xmlns="http:/ki.ujep.cz/ns/qc_ast" xmlns:xs="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" indent="yes"/>

  <xsl:template match="py:Assign">
     <assignment tags="statement simple_statement"><xsl:apply-templates/></assignment>
  </xsl:template>

  <xsl:template match="py:AnnAssign">
      <assignment tags="statement simple_statement definition" definition="true"><xsl:apply-templates/>
      </assignment>
  </xsl:template>

  <xsl:template match="py:Assign|py:AnnAssign" mode="declaration">
    <declaration type="class_field" tags="declaration definition" definition="true">
      <xsl:attribute name="target">
            <xsl:value-of select="py:target/qc:expression/py:Name/@id"/>
      </xsl:attribute>
      <xsl:apply-templates select="py:annotation"/>
      <xsl:if test="py:value">
        <value type="init">
          <xsl:apply-templates select="py:value/*"/>
        </value>
      </xsl:if>
    </declaration>
  </xsl:template>

  <xsl:template match="py:AugAssign">
        <assignment tags="statement simple_statement operator {py:operator/@type}" definition="false"
                 augmented_operator="{py:operator/@symbol}">
          <xsl:apply-templates/>
        </assignment>
  </xsl:template>

  <xsl:template match="py:AugAssign/py:operator"/>

  <xsl:template match="py:Assign/py:targets|py:AnnAssign/py:target|py:AugAssign/py:target">
    <target><xsl:apply-templates/></target>
  </xsl:template>

  <xsl:template match="py:Assign/py:value|py:AnnAssign/py:value|py:AnnAssign/py:value|py:AugAssign/py:value">
    <value><xsl:apply-templates/></value>
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
    <variable name="{@id}" tags="expression simple"/>
  </xsl:template>


  <xsl:template match="py:Attribute">
    <attribute longname="{@longname}" name="{@name}" tags="expression">
      <xsl:apply-templates select="py:value/*"/>
    </attribute>
  </xsl:template>

  <xsl:template match="py:BinOp">
    <operator arity="2" symbol="{py:operator/@symbol}"
              tags="expression operator {py:operator/@type}">
      <xsl:apply-templates select="py:left/*"/>
      <xsl:apply-templates select="py:right/*"/>
    </operator>
  </xsl:template>

   <xsl:template match="py:BoolOp">
    <operator arity="2" symbol="{py:operator/@symbol}"
              tags="expression operator {py:operator/@type} nonstrict">
      <xsl:apply-templates select="py:values/*"/>
    </operator>
  </xsl:template>

    <xsl:template match="py:Compare[count(py:ops/*) = 1]">
    <operator arity="2" symbol="{py:ops/py:operator/@symbol}"
              tags="expression operator {py:ops/py:operator/@type}">
      <xsl:apply-templates select="py:left/*"/>
      <xsl:apply-templates select="py:comparators/*"/>
    </operator>
  </xsl:template>

    <xsl:template match="py:UnaryOp">
    <operator arity="1" symbol="{py:operator/@symbol}" tags="expression operator {py:operator/@type}">
      <xsl:apply-templates select="py:operand/*"/>
    </operator>
  </xsl:template>

  <xsl:template match="py:Subscript">
    <indexing tags="expression">
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
    <range tags="expression literal">
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
    <literal tags = "expression simple literal {@type}">
      <xsl:apply-templates select="@*"/>
      <xsl:if test="@type='NoneType'">
        <xsl:attribute name="value">None</xsl:attribute>
      </xsl:if>
    </literal>
  </xsl:template>

  <xsl:template match="py:List">
    <collection type="list" tags="expression literal">
      <xsl:apply-templates select="py:elts/*"/>
    </collection>
  </xsl:template>

  <xsl:template match="py:Tuple">
    <collection type="tuple" tags="expression literal">
      <xsl:apply-templates select="py:elts/*"/>
    </collection>
  </xsl:template>

  <xsl:template match="py:Set">
    <collection type="set" tags="expression literal">
      <xsl:apply-templates select="py:elts/*"/>
    </collection>
  </xsl:template>

  <xsl:template match="py:Dict">
    <collection type="dictionary" tags="expression literal">
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
    <statement type="expression" tags="statement simple_statement">
      <xsl:apply-templates select="py:value/*"/>
    </statement>
  </xsl:template>

  <xsl:template match="py:Await">
   <suspend type="await" tags="expression async jump">
        <xsl:apply-templates select="py:value/*"/>
   </suspend>
  </xsl:template>

  <xsl:template match="py:Yield">
     <suspend type="yield" tags="expression coroutine jump">
        <xsl:apply-templates select="py:value/*"/>
     </suspend>
  </xsl:template>

  <xsl:template match="py:YieldFrom">
    <suspend type="yield_from" tags="expression coroutine jump">
        <xsl:apply-templates select="py:value/*"/>
    </suspend>
  </xsl:template>

  <xsl:template match="py:Call[py:func/py:Name]"> <!-- call of named function-->
    <call name="{py:func/py:Name/@id}" complex="false" tags="expression">
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
    <call complex="true" tags="expression">
      <xsl:if test="py:func/py:Attribute/@name">
          <xsl:attribute name="name">.<xsl:value-of select="py:func/py:Attribute/@name"/></xsl:attribute>
      </xsl:if>
      <function>
        <xsl:apply-templates select="py:func/*"/>
      </function>
      <arguments>
        <xsl:call-template name="call_args"/>
      </arguments>
    </call>
  </xsl:template>

  <xsl:template name="CwAsync">
    <xsl:param name="ifasync"/>
    <xsl:param name="tags"/>
     <xsl:choose>
        <xsl:when test="$ifasync = 'true'">
          <xsl:attribute name="async">true</xsl:attribute>
          <xsl:attribute name="tags"><xsl:value-of select="$tags"/> async</xsl:attribute>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="tags"><xsl:value-of select="$tags"/></xsl:attribute>
        </xsl:otherwise>
      </xsl:choose>
  </xsl:template>

  <xsl:template match="py:For|py:AsyncFor">
    <foreach>
      <xsl:call-template name="CwAsync">
        <xsl:with-param name="ifasync"><xsl:value-of select="boolean(self::py:AsyncFor)"/></xsl:with-param>
        <xsl:with-param name="tags">statement nesting_statement loop declaration</xsl:with-param>
      </xsl:call-template>
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
    </foreach>
  </xsl:template>

  <xsl:template match="py:elts" mode="compact_tuple">
    <xsl:for-each select="py:Name"><xsl:if test="position() > 1">,</xsl:if><xsl:value-of select="@id"/></xsl:for-each>
  </xsl:template>

  <xsl:template match="py:Pass">
    <statement type="empty" tags="statement simple_statement"/>
  </xsl:template>

  <xsl:template match="py:Break">
    <statement  type="break" tags="statement simple_statement jump"/>
  </xsl:template>

  <xsl:template match="py:Continue">
    <statement  type="continue" tags="statement simple_statement jump"/>
  </xsl:template>

  <xsl:template match="py:Return">
    <statement type="return" tags="statement simple_statement jump">
       <xsl:apply-templates select="py:value/*"/>
    </statement>
  </xsl:template>

    <xsl:template match="py:Raise">
    <statement type="throw" tags="statement simple_statement exception jump">
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
    <statement type="delete" tags="statement simple_statement">
      <xsl:apply-templates select="py:targets/*"/>
    </statement>
  </xsl:template>

  <xsl:template match="py:Assert">
    <assert tags="statement simple_statement exception jump conditional">
      <condition>
        <xsl:apply-templates select="py:test/*"/>
      </condition>
      <message>
         <xsl:apply-templates select="py:msg/*"/>
      </message>
    </assert>
  </xsl:template>

  <xsl:template match="py:While">
    <while tags="statement nesting_statement loop conditional">
      <condition>
        <xsl:apply-templates select="py:test/*"/>
      </condition>
      <block>
        <xsl:apply-templates select="py:body/*"/>
      </block>
    </while>
  </xsl:template>

  <xsl:template match="py:If">
      <if tags="statement nesting_statement conditional">
        <condition>
          <xsl:apply-templates select="py:test/*"/>
        </condition>
        <then>
          <xsl:apply-templates select="py:body/*"/>
        </then>
        <xsl:if test="py:orelse/*">
          <else>
            <xsl:apply-templates select="py:orelse/*"/>
          </else>
        </xsl:if>
      </if>
  </xsl:template>

  <xsl:template match="py:FunctionDef|py:AsyncFunctionDef">
    <function name="{@name}">
      <xsl:call-template name="CwAsync">
        <xsl:with-param name="ifasync"><xsl:value-of select="boolean(self::py:AsyncFunctionDef)"/></xsl:with-param>
        <xsl:with-param name="tags">statement nesting_statement definition</xsl:with-param>
      </xsl:call-template>
      <xsl:if test="self::py:AsyncFunctionDef">
        <xsl:attribute name="async">true</xsl:attribute>
      </xsl:if>
      <xsl:call-template name="fparam"/>
      <xsl:if test="py:returns">
        <annotation>
          <xsl:apply-templates select="py:returns/*"/>
        </annotation>
      </xsl:if>
      <block>
        <xsl:apply-templates select="py:body/*"/>
      </block>
      <xsl:if test="py:decorator_list/*">
        <xsl:apply-templates select="py:decorator_list"/>
      </xsl:if>
    </function>
  </xsl:template>

  <xsl:template match="py:Lambda">
    <lambda tags="expression literal">
      <xsl:call-template name="fparam"/>
      <xsl:apply-templates select="py:body/*"/>
    </lambda>
  </xsl:template>

  <xsl:template name="fparam">
    <parameters>
        <xsl:if test="py:args/py:arguments/py:vararg">
          <xsl:attribute name="vararg"><xsl:value-of select="py:args/py:arguments/py:vararg/py:arg/@arg"/></xsl:attribute>
        </xsl:if>
        <xsl:if test="py:args/py:arguments/py:kwarg">
          <xsl:attribute name="kwarg"><xsl:value-of select="py:args/py:arguments/py:kwarg/py:arg/@arg"/></xsl:attribute>
        </xsl:if>
        <xsl:for-each select="py:args/py:arguments/py:posonlyargs/py:arg">
          <xsl:variable name="argpos" select="count(../../py:args)+last()-position()+1"/>
          <parameter name="{@arg}" positional="true" named="false">
            <xsl:if test="count(../../py:defaults/*)>$argpos">
              <value type="default">
                <xsl:apply-templates select="../../py:defaults/*[last()-$argpos]"/>
              </value>
            </xsl:if>
            <xsl:apply-templates select="py:annotation"/>
          </parameter>
        </xsl:for-each>
        <xsl:for-each select="py:args/py:arguments/py:args/py:arg">
          <xsl:variable name="argpos" select="last()-position()"/>
          <parameter name="{@arg}" positional="true" named="true">
            <xsl:if test="count(../../py:defaults/*)>$argpos">
              <value type="default">
                <xsl:apply-templates select="../../py:defaults/*[last()-$argpos]"/>
              </value>
            </xsl:if>
            <xsl:apply-templates select="py:annotation"/>
          </parameter>
        </xsl:for-each>
        <xsl:for-each select="py:args/py:arguments/py:kwonlyargs/py:arg">
          <xsl:variable name="argpos"  select="position()"/>
          <parameter name="{@arg}" positional="false" named="true">
            <xsl:if test="name(../../py:kw_defaults/*[position()=$argpos])!='py:empty'">
              <value type="default">
                <xsl:apply-templates select="../../py:kw_defaults/*[position()=$argpos]"/>
              </value>
            </xsl:if>
            <xsl:apply-templates select="py:annotation"/>
          </parameter>
        </xsl:for-each>
      </parameters>
  </xsl:template>

  <xsl:template match="py:annotation">
    <annotation>
      <xsl:apply-templates select="*"/>
    </annotation>
  </xsl:template>
  
  <xsl:template match="py:ImportFrom">
    <import from="{@module}" which="variable class function" tags="statement simple_statement">
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

  <xsl:template match="py:Import" >
    <import which="module" tags="statement simple_statement">
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
    <comprehension tags="expression loop">
      <xsl:attribute name="type">
        <xsl:choose>
          <xsl:when test="self::py:ListComp">list</xsl:when>
          <xsl:when test="self::py:SetComp">set</xsl:when>
          <xsl:when test="self::py:DictComp">dictionary</xsl:when>
          <xsl:when test="self::py:GeneratorExp">iterable</xsl:when>
        </xsl:choose>
      </xsl:attribute>
        <xsl:choose>
          <xsl:when test="py:elt">
              <xsl:apply-templates select="py:elt/*"/>
          </xsl:when>
          <xsl:when test="py:key">
            <pair>
              <xsl:apply-templates select="py:key/*"/>
              <xsl:apply-templates select="py:value/*"/>
            </pair>
          </xsl:when>
        </xsl:choose>
      <xsl:for-each select="py:generators/py:comprehension">
        <generator tags="expression declaration definition" definition="true">
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
    <class name="{@name}" tags="statement nesting_statement definition">
      <xsl:for-each select="py:bases//py:Name">
       <base><xsl:value-of select="@id"/></base>
      </xsl:for-each>
        <xsl:for-each select="py:body/py:Assign|py:body/py:AnnAssign">
          <field type="class" visibility="public">
            <xsl:apply-templates select="." mode="declaration"/>
          </field>
        </xsl:for-each>
        <xsl:for-each select="py:body/py:FunctionDef|py:body/py:AsyncFunctionDef">
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
        <xsl:if test="py:decorator_list/*">
          <xsl:apply-templates select="py:decorator_list"/>
        </xsl:if>
    </class>
  </xsl:template>

  <xsl:template match="py:With|py:AsyncWith">
    <context type="with" tags="statement nesting_statement">
      <xsl:if test="self::py:AsyncWith">
        <xsl:attribute name="async">true</xsl:attribute>
      </xsl:if>
      <items>
        <xsl:apply-templates select="py:items/py:withitem"/>
      </items>
      <block>
        <xsl:apply-templates select="py:body/*"/>
      </block>
    </context>
  </xsl:template>

  <xsl:template match="py:withitem">
    <xsl:choose>
      <xsl:when test="py:optional_vars">
        <declaration type="context_manager" tags="declaration">
          <xsl:choose>
            <xsl:when test="py:optional_vars/qc:expression/py:Name/@id">
              <xsl:attribute name="target">
                <xsl:value-of select="py:optional_vars/qc:expression/py:Name/@id"/>
              </xsl:attribute>
            </xsl:when>
            <xsl:when test="py:optional_vars/qc:expression/py:Tuple">
              <xsl:attribute name="targets">
                <xsl:apply-templates select="py:optional_vars/qc:expression/py:Tuple/py:elts" mode="compact_tuple"/>
              </xsl:attribute>
            </xsl:when>
          </xsl:choose>
          <value type="init">
            <xsl:apply-templates select="py:context_expr/*"/>
          </value>
        </declaration>
      </xsl:when>
      <xsl:otherwise>
        <value type="init">
          <xsl:apply-templates select="py:context_expr/*"/>
        </value>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="py:Global|py:Nonlocal"> <!-- scope declarations-->
    <declaration definition="False" tags="declaration">
      <xsl:attribute name="type">
        <xsl:choose>
          <xsl:when test="self::py:Global">global</xsl:when>
          <xsl:when test="self::py:Nonlocal">nonlocal</xsl:when>
        </xsl:choose>
      </xsl:attribute>
      <xsl:attribute name="targets"><xsl:value-of select="py:names"/></xsl:attribute>
    </declaration>
  </xsl:template>

  <xsl:template match="py:Try|py:TryStar">
    <try tags="statement nesting_statement exception">
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
          <declaration type="exception_handler" target="{@name}" tags="declaration"/>
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
    <match type="pattern" tags="statement nesting_statement conditional">
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

  <xsl:template match="py:JoinedStr">
    <interpolated_string tags="expression literal string">
      <xs:apply-templates select="py:values/*"/>
    </interpolated_string>
  </xsl:template>

  <xsl:template match="py:FormattedValue">
    <interpolated_string>
      <xsl:call-template name="formatted"/>
    </interpolated_string>
  </xsl:template>

  <xsl:template match="py:JoinedStr//py:FormattedValue">
      <xsl:call-template name="formatted"/>
  </xsl:template>

   <xsl:template name="formatted">
      <formatted>
        <xsl:attribute name="conversion">
          <xsl:choose>
            <xsl:when test="@conversion='-1'"></xsl:when>
            <xsl:when test="@conversion='115'">!s</xsl:when>
            <xsl:when test="@conversion='114'">!r</xsl:when>
            <xsl:when test="@conversion='97'">!a</xsl:when>
          </xsl:choose>
        </xsl:attribute>
        <value><xsl:apply-templates select="py:value/*"/></value>
        <format><xsl:apply-templates select="py:format_spec/py:JoinedStr/py:values/*"/></format>
      </formatted>
  </xsl:template>


  <xsl:template match="@*|*|text()"> <!-- copying of all attributes, elements and text nodes -->
    <xsl:copy>
      <xsl:apply-templates select="@*|*|text()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="py:IfExp">
    <cond_expr tags="expression conditional nonstrict">
      <condition><xsl:apply-templates select="py:test/*"/></condition>
      <then><xsl:apply-templates select="py:body/*"/></then>
      <else><xsl:apply-templates select="py:orelse/*"/></else>
    </cond_expr>
  </xsl:template>
</xsl:stylesheet>

