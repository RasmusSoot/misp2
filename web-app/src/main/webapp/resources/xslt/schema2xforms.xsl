<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:xhtml="http://www.w3.org/1999/xhtml" 
    xmlns:xforms="http://www.w3.org/2002/xforms"
    xmlns:events="http://www.w3.org/2001/xml-events"
    xmlns:xsd="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  	xmlns:xxforms="http://orbeon.org/oxf/xml/xforms"
    exclude-result-prefixes="">
<xsl:import href="schematraverse.xsl"/>
<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes" /> 

<!-- Debug flag. -->
<xsl:param name="debug" select="false()"/>

<!-- Name of the element to generate, by default the first element. -->
<xsl:param name="element" select="string(/xsd:schema/xsd:element[1]/@name)"/>
<!-- Name of the form, by default the name of the element. -->
<xsl:param name="formname" select="$element"/>
<!-- URL where to submit the result, by default file 'formname.xml'. -->
<xsl:param name="url" select="concat($formname, '.xml')"/>
<!-- Submission method, by default 'put'. -->
<xsl:param name="method" select="'put'"/>

<!-- Main template. -->
<xsl:template match="/">
  <xsl:apply-imports>
    <xsl:with-param name="name" select="$element"/>
    <xsl:with-param name="what" select="'element'"/>
    <xsl:with-param name="context" select="/xsd:schema"/>
    <xsl:with-param name="formtype" select="'input'" tunnel="yes"/>
  </xsl:apply-imports>
</xsl:template>

<!-- Generate html only when element is found. -->
<xsl:template match="xsd:element">
  <xhtml:html>
    <xsl:apply-templates select="." mode="html"/>
  </xhtml:html>
</xsl:template>

<xsl:template match="xsd:element" mode="html">
  <xhtml:head>
    <xsl:apply-templates select="." mode="head"/>
  </xhtml:head>
  <xhtml:body>
    <xsl:apply-templates select="." mode="body"/>
  </xhtml:body>
</xsl:template>

<xsl:template match="xsd:element" mode="head">
  <!-- Generate title. -->
  <xsl:apply-templates select="." mode="title"/>
  <xforms:model>
    <xforms:instance id="{$formname}.instance">
      <!-- Generate instance. -->
      <xsl:apply-templates select="." mode="instance"/>
    </xforms:instance>
    <!-- Generate lookup instances. -->
    <!-- No need to generate lookup on input forms. -->
    <!--xsl:apply-templates select="." mode="lookup"/-->
    <!-- Generate helper instance. -->
    <xsl:call-template name="createTempInstance"/>
    <!-- Generate submission and events. -->
    <xforms:submission id="{$formname}.submission" action="{$url}" method="{$method}">
      <xforms:action events:event="xforms-submit">
        <xforms:setvalue ref="instance('temp')/relevant" value="false()"/>
      </xforms:action>
      <xforms:action events:event="xforms-submit-done">
        <xforms:setvalue ref="instance('temp')/relevant" value="true()"/>
      </xforms:action>
      <xforms:action events:event="xforms-submit-error">
        <xforms:setvalue ref="instance('temp')/relevant" value="true()"/>
      </xforms:action>
      <xforms:message level="modal" events:event="xforms-submit-done">Submit done</xforms:message>
      <xforms:message level="modal" events:event="xforms-submit-error">Submit error</xforms:message>
    </xforms:submission>
    <!-- Copy schema. -->
    <!-- Our bindings are good enough, schema is not needed. -->
    <!--xsl:copy-of select="."/-->
    <!-- Generate bindings. -->
    <xsl:apply-templates select="." mode="bind">
      <xsl:with-param name="element" select="concat('/', @name)" tunnel="yes"/>
    </xsl:apply-templates>
  </xforms:model>
</xsl:template>

<xsl:template match="xsd:element" mode="body">
  <!-- Generate heading. -->
  <xsl:apply-templates select="." mode="heading"/>
  <!-- Generate input form. -->
  <xsl:apply-templates select="." mode="form">
    <xsl:with-param name="formtype" select="'input'" tunnel="yes"/>
    <xsl:with-param name="element" select="concat('/', @name)" tunnel="yes"/>
  </xsl:apply-templates>
  <xforms:submit submission="{$formname}.submission">
    <xforms:label>Submit</xforms:label>
  </xforms:submit>
</xsl:template>

<xsl:template name="createTempInstance">
  <xsl:if test="$debug"><xsl:message select="concat('createTempInstance: ', name(), ', ', @name)"/></xsl:if>
  <xforms:instance id="temp">
    <temp xmlns=""><relevant xsi:type="boolean">true</relevant></temp>
  </xforms:instance>
</xsl:template>

<!-- Instance generation. -->

<xsl:template name="attributesFirst">
  <xsl:apply-templates select="xsd:attribute" mode="#current"/>
  <xsl:apply-templates select="xsd:attributeGroup" mode="#current"/>
  <xsl:apply-templates select="* except (xsd:attribute | xsd:attributeGroup)" mode="#current"/>
</xsl:template>

<xsl:template match="xsd:complexType" mode="instance">
  <xsl:if test="$debug"><xsl:message select="concat('instance: ', name(), ', ', @name)"/></xsl:if>
  <xsl:call-template name="attributesFirst"/>
</xsl:template>

<xsl:template match="xsd:choice" mode="instance">
  <xsl:if test="$debug"><xsl:message select="concat('instance: ', name())"/></xsl:if>
  <!-- Add choice element, which will be made non-relevant for submit. -->
  <xsl:element name="choice-{generate-id()}"><xsl:value-of select="generate-id(*[1])"/></xsl:element>
  <xsl:apply-imports/>
</xsl:template>

<xsl:template match="xsd:restriction" mode="instance">
  <xsl:if test="$debug"><xsl:message select="concat('instance: ', name(), ', ', @base)"/></xsl:if>
  <!-- Restrictions of base type first. -->
  <xsl:apply-templates select="/" mode="#current">
    <xsl:with-param name="name" select="@base"/>
    <!-- Consider only simple types, because in case of complex type 
         the restriction must duplicate all constraints of base type. -->
    <xsl:with-param name="what" select="'simpleType'"/>
    <xsl:with-param name="context" select="."/>
  </xsl:apply-templates>
  <!-- Then restrictions of this type. -->
  <xsl:call-template name="attributesFirst"/>
</xsl:template>

<xsl:template match="xsd:extension" mode="instance">
  <xsl:if test="$debug"><xsl:message select="concat('instance: ', name(), ', ', @base)"/></xsl:if>
  <!-- Elements of base type first. -->
  <xsl:apply-templates select="/" mode="#current">
    <xsl:with-param name="name" select="@base"/>
    <xsl:with-param name="what" select="'(simple|complex)Type'"/>
    <xsl:with-param name="context" select="."/>
  </xsl:apply-templates>
  <!-- Add additional elements/attributes, if defined by extension. -->
  <xsl:call-template name="attributesFirst"/>
</xsl:template>

<xsl:template match="xsd:sequence" mode="instance">
  <xsl:if test="$debug"><xsl:message select="concat('instance: ', name())"/></xsl:if>
  <xsl:apply-imports>
    <xsl:with-param name="maxOccurs" select="@maxOccurs" tunnel="yes"/>
  </xsl:apply-imports>
</xsl:template>

<xsl:template match="xsd:element" mode="instance">
  <xsl:param name="element" tunnel="yes"/>
  <xsl:param name="maxOccurs" tunnel="yes"/>
  <xsl:param name="tnsprefix" tunnel="yes"/>
  <xsl:param name="usenamespace" tunnel="yes"/>
  <xsl:if test="$debug"><xsl:message select="concat('instance: ', name(), ', ', @name)"/></xsl:if>
  <xsl:choose>
    <!-- Check if based on existing element, then let imported stylesheet resolve it. -->
    <xsl:when test="@ref">
      <xsl:apply-imports/>
    </xsl:when>
    <!-- Otherwise generate element. -->
    <xsl:otherwise>
  	  <xsl:variable name="usenamespace" select="$usenamespace or ancestor::xsd:schema/@elementFormDefault='qualified'" />
      <xsl:variable name="maxOccurs" select="if (@maxOccurs) then @maxOccurs else if ($maxOccurs) then $maxOccurs else '1'"/>
      <!-- Generate minOccurs instances of element. Add 1 for prototype element when maxOccurs > 1. -->
      <xsl:variable name="minOccurs" select="xsd:integer(if ($maxOccurs = 'unbounded' or number($maxOccurs) &gt; 1) then (if (exists(@minOccurs)) then @minOccurs else 1) + 1 else (if (@minOccurs &gt; 1) then @minOccurs else 1))"/>
      <!-- for-each resets current node, the return clause in for cycle helps to overcome that. -->
      <xsl:for-each select="for $x in 1 to $minOccurs return .">
        <xsl:element name="{if ($usenamespace) then concat($tnsprefix, ':') else ''}{normalize-space(if ($element) then $element else @name)}" namespace="{if ($usenamespace) then ancestor::xsd:schema/@targetNamespace else ''}">
          <!-- If element has type attribute, then set xsi:type. -->
          <xsl:apply-templates select="." mode="type"/>
          <!-- Generate attributes and subelements. -->
          <!-- Should use apply-imports instead, but it's not possible, because for-each resets current template. -->
          <xsl:call-template name="traverseElement">
            <xsl:with-param name="element" tunnel="yes"/>
            <xsl:with-param name="maxOccurs" tunnel="yes"/>
            <xsl:with-param name="usenamespace" tunnel="yes"/>
          </xsl:call-template>
          <!-- Generate default value. -->
          <xsl:apply-templates select="." mode="default"/>
        </xsl:element>
      </xsl:for-each>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="xsd:attribute" mode="instance">
  <xsl:if test="$debug"><xsl:message select="concat('instance: ', name(), ', ', @name)"/></xsl:if>
  <xsl:choose>
    <!-- Check if based on existing attribute, then let imported stylesheet resolve it. -->
    <xsl:when test="@ref">
      <xsl:apply-imports/>
    </xsl:when>
    <!-- Otherwise generate attribute. -->
    <xsl:otherwise>
      <!--xsl:attribute name="{@name}" namespace="{ancestor::xsd:schema/@targetNamespace}"-->
      <xsl:attribute name="{@name}" namespace="">
        <!-- Do not attach type to attribute. -->
        <!--xsl:apply-imports/-->
        <!-- Generate default value. -->
        <xsl:apply-templates select="." mode="default"/>
      </xsl:attribute>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="/" mode="instance">
  <xsl:param name="name"/>
  <xsl:param name="what"/>
  <xsl:param name="context"/>
  <xsl:if test="$debug"><xsl:message select="concat('instance: ', $name, ', ', $what)"/></xsl:if>

  <!-- Resolve type/element/attribute. -->
  <xsl:apply-imports>
    <xsl:with-param name="name" select="$name"/>
    <xsl:with-param name="what" select="$what"/>
    <xsl:with-param name="context" select="$context"/>
  </xsl:apply-imports>
</xsl:template>

<xsl:template match="xsd:element | xsd:attribute" mode="default">
  <xsl:if test="$debug"><xsl:message select="concat('default: ', @default, ', ', @fixed)"/></xsl:if>
  <xsl:variable name="qname" select="resolve-QName(@type, .)"/>
  <xsl:variable name="localname" select="local-name-from-QName($qname)"/>
  <xsl:variable name="namespace" select="namespace-uri-from-QName($qname)"/>
  <xsl:choose>
    <!-- Set initial value, if there is default or fixed value. -->
    <!-- NB! Must be done after generation of attributes. -->
    <xsl:when test="@default">
      <xsl:value-of select="@default"/>
    </xsl:when>
    <xsl:when test="@fixed">
      <xsl:value-of select="@fixed"/>
    </xsl:when>
    <!-- Boolean fields are initially false. -->
    <xsl:when test="$localname = 'boolean' and $namespace = 'http://www.w3.org/2001/XMLSchema'">false</xsl:when>
  </xsl:choose>
</xsl:template>

<!-- Lookup instance generation. -->

<xsl:template match="xsd:restriction" mode="lookup">
  <xsl:param name="formtype" tunnel="yes"/>
  <xsl:if test="$debug"><xsl:message select="concat('lookup: ', name(), ', ', @base)"/></xsl:if>
  <xsl:choose>
    <!-- If contains enumeration, then generate instance. -->
    <xsl:when test="xsd:enumeration">
      <xforms:instance id="lookup-{generate-id()}">
        <lookup xmlns="">
          <xsl:apply-templates mode="#current"/>
        </lookup>
      </xforms:instance>
    </xsl:when>
    <!-- Otherwise base type might contain enumeration. -->
    <xsl:otherwise>
      <xsl:apply-imports/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="xsd:enumeration" mode="lookup">
  <item value="{@value}" xmlns="">
    <xsl:apply-templates select="." mode="lookup-label"/>
  </item>
</xsl:template>

<xsl:template match="xsd:enumeration" mode="lookup-label">
  <xsl:value-of select="@value"/>
</xsl:template>

<!-- Binding generation. -->

<xsl:template match="/" mode="bind">
  <xsl:param name="name"/>
  <xsl:param name="what"/>
  <xsl:param name="context"/>
  <xsl:param name="formtype" tunnel="yes"/>
  <xsl:if test="$debug"><xsl:message select="concat('bind: ', $name, ', ', $what)"/></xsl:if>

  <!-- Resolve type name. -->
  <xsl:variable name="qname" select="resolve-QName($name, $context)"/>
  <xsl:variable name="localname" select="local-name-from-QName($qname)"/>
  <xsl:variable name="namespace" select="namespace-uri-from-QName($qname)"/>

  <!-- If type is XML Schema type, then include that in binding. -->
  <xsl:if test="ends-with($what, 'Type') and $namespace = 'http://www.w3.org/2001/XMLSchema'">
    <!-- Use only type name. There is corresponding XForms type for each Schema type. XForms types are better. -->
    <xsl:attribute name="type" select="concat('xforms:', $localname)"/>
  </xsl:if>

  <!-- Resolve type/element/attribute. -->
  <xsl:apply-imports>
    <xsl:with-param name="name" select="$name"/>
    <xsl:with-param name="what" select="$what"/>
    <xsl:with-param name="context" select="$context"/>
  </xsl:apply-imports>
</xsl:template>

<xsl:template match="xsd:choice" mode="bind">
  <xsl:param name="choiceref" tunnel="yes"/>
  <xsl:param name="choiceid" tunnel="yes"/>
  <xsl:param name="relevant" tunnel="yes"/>
  <xsl:param name="formtype" tunnel="yes"/>
  <xsl:if test="$debug"><xsl:message select="concat('bind: ', name())"/></xsl:if>
  <xsl:variable name="relevant">
    <xsl:value-of select="$relevant"/>
    <xsl:apply-templates select="." mode="relevant">
      <xsl:with-param name="choiceid" select="if ($choiceid) then $choiceid else generate-id()" tunnel="yes"/>
    </xsl:apply-templates>
  </xsl:variable>
  <xsl:if test="$formtype = 'input'">
    <!-- Make choice element non-relevant during submit. -->
    <xforms:bind nodeset="choice-{generate-id()}" relevant="boolean-from-string(instance('temp')/relevant){if ($relevant != '') then ' and ' else ''}{$relevant}"/>
  </xsl:if>
  <xsl:apply-imports>
    <xsl:with-param name="choiceref" select="concat('choice-', generate-id())" tunnel="yes"/>
    <xsl:with-param name="choiceid" tunnel="yes"/>
    <xsl:with-param name="relevant" select="$relevant" tunnel="yes"/>
  </xsl:apply-imports>
</xsl:template>

<xsl:template match="xsd:choice/xsd:group | xsd:choice/xsd:sequence" mode="bind">
  <xsl:if test="$debug"><xsl:message select="concat('bind: ', name())"/></xsl:if>
  <!-- Sequence or group below choice always creates new choiceid. -->
  <xsl:apply-imports>
    <xsl:with-param name="choiceid" select="generate-id()" tunnel="yes"/>
  </xsl:apply-imports>
</xsl:template>

<!-- If we would match only sequence, then it would conflict with template above. -->
<xsl:template match="xsd:complexType/xsd:sequence" mode="bind">
  <xsl:if test="$debug"><xsl:message select="concat('bind: ', name())"/></xsl:if>
  <xsl:apply-imports>
    <xsl:with-param name="maxOccurs" select="@maxOccurs" tunnel="yes"/>
  </xsl:apply-imports>
</xsl:template>

<xsl:template match="xsd:element" mode="bind">
  <xsl:param name="element" tunnel="yes"/>
  <xsl:param name="choiceid" tunnel="yes"/>
  <xsl:param name="formtype" tunnel="yes"/>
  <xsl:param name="maxOccurs" tunnel="yes"/>
  <xsl:param name="tnsprefix" tunnel="yes"/>
  <xsl:param name="usenamespace" tunnel="yes"/>
  <xsl:if test="$debug"><xsl:message select="concat('bind: ', name(), ', ', @name)"/></xsl:if>
  <xsl:choose>
    <xsl:when test="@ref">
      <xsl:apply-imports/>
    </xsl:when>
    <xsl:otherwise>
  	  <xsl:variable name="usenamespace" select="$usenamespace or ancestor::xsd:schema/@elementFormDefault='qualified'" />
      <xsl:variable name="ref" select="normalize-space(if ($element) then $element else @name)"/>
      <xsl:variable name="ref" select="
		  if ($usenamespace and not(contains($ref, ':'))) 
		  then concat($tnsprefix, ':', $ref) 
		  else $ref" />
	  <xsl:variable name="maxOccurs" select="if (@maxOccurs) then @maxOccurs else if ($maxOccurs) then $maxOccurs else '1'"/>
      <xforms:bind nodeset="{$ref}">
        <xsl:if test="$usenamespace">
          <xsl:namespace name="{$tnsprefix}" select="ancestor::xsd:schema/@targetNamespace"/>
        </xsl:if>
        <!-- Do not create normal mips when maxOccurs > 1, becaus they would clash with bind to make last item invisible. -->
        <xsl:if test="not($maxOccurs = 'unbounded' or number($maxOccurs) &gt; 1)">
          <xsl:apply-templates select="." mode="mips">
            <!-- If choiceid has not been generated so far, then generate it. -->
            <xsl:with-param name="choiceid" select="if ($choiceid) then $choiceid else generate-id()" tunnel="yes"/>
          </xsl:apply-templates>
        </xsl:if>
        <xsl:apply-imports>
          <xsl:with-param name="element" tunnel="yes"/>
          <xsl:with-param name="choiceref" tunnel="yes"/>
          <xsl:with-param name="choiceid" tunnel="yes"/>
          <xsl:with-param name="relevant" tunnel="yes"/>
          <xsl:with-param name="usenamespace" tunnel="yes"/>
        </xsl:apply-imports>
      </xforms:bind>
      <xsl:if test="($maxOccurs = 'unbounded' or number($maxOccurs) &gt; 1) and $formtype = 'input'">
        <!-- Make last item in repeat invisible, so added row always has the same default values. -->
        <xforms:bind nodeset="{$ref}[count(../{$ref})]" relevant="false()"/>
      </xsl:if>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="xsd:attribute" mode="bind">
  <xsl:if test="$debug"><xsl:message select="concat('bind: ', name(), ', ', @name)"/></xsl:if>
  <xsl:choose>
    <xsl:when test="@ref">
      <xsl:apply-imports/>
    </xsl:when>
    <xsl:otherwise>
      <xforms:bind nodeset="{concat('@', @name)}">
        <xsl:apply-templates select="." mode="mips"/>
        <xsl:apply-imports/>
      </xforms:bind>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="xsd:element | xsd:attribute" mode="mips">
  <xsl:if test="$debug"><xsl:message select="concat('mips: ', name(), ', ', @name)"/></xsl:if>
  <!-- readonly -->
  <xsl:variable name="readonly" as="text() *">
    <xsl:apply-templates select="." mode="readonly"/>
  </xsl:variable>
  <xsl:if test="not(empty($readonly))">
    <xsl:attribute name="readonly" select="string-join($readonly, ' and ')"/>
  </xsl:if>
  <!-- required -->
  <xsl:variable name="required" as="text() *">
    <xsl:apply-templates select="." mode="required"/>
  </xsl:variable>
  <xsl:if test="not(empty($required))">
    <xsl:attribute name="required" select="string-join($required, ' and ')"/>
  </xsl:if>
  <!-- relevant -->
  <xsl:variable name="relevant" as="text() *">
    <xsl:apply-templates select="." mode="relevant"/>
  </xsl:variable>
  <xsl:if test="not(empty($relevant))">
    <xsl:attribute name="relevant" select="string-join($relevant, ' and ')"/>
  </xsl:if>
  <!-- calculate -->
  <xsl:variable name="calculate" as="text() *">
    <xsl:apply-templates select="." mode="calculate"/>
  </xsl:variable>
  <xsl:if test="not(empty($calculate))">
    <xsl:attribute name="calculate" select="string-join($calculate, ' and ')"/>
  </xsl:if>
  <!-- constraint -->
  <xsl:variable name="constraint" as="text() *">
    <xsl:apply-templates select="." mode="constraint"/>
  </xsl:variable>
  <xsl:if test="not(empty($constraint))">
    <!-- Empty content is also valid, also add true() because all expressions start with and. -->
    <xsl:attribute name="constraint" select="concat('. = '''' or (', string-join($constraint, ' and '), ')')"/>
  </xsl:if>
</xsl:template>

<xsl:template match="xsd:element | xsd:attribute" mode="readonly">
  <xsl:if test="$debug"><xsl:message select="concat('readonly: ', name(), ', ', @name)"/></xsl:if>
  <!-- If there is fixed attribute, then the field is read-only. -->
  <xsl:if test="@fixed">true()</xsl:if>
</xsl:template>

<xsl:template match="xsd:element | xsd:attribute" mode="required">
  <xsl:if test="$debug"><xsl:message select="concat('required: ', name(), ', ', @name)"/></xsl:if>
  <!-- If minOccurs = 1 for element or use="required" for attribute, then the field is required. -->
  <!-- minOccurs = 1 requires existance of element, it doesn't require it to be non-empty. -->
  <!--xsl:if test="@minOccurs &gt; 0 or @use='required'">true()</xsl:if-->
</xsl:template>

<xsl:template match="xsd:element | xsd:attribute | xsd:choice" mode="relevant">
  <xsl:param name="choiceref" tunnel="yes"/>
  <xsl:param name="choiceid" tunnel="yes"/>
  <xsl:param name="relevant" tunnel="yes"/>
  <xsl:param name="formtype" tunnel="yes"/>
  <xsl:if test="$debug"><xsl:message select="concat('relevant: ', name(), ', ', @name)"/></xsl:if>
  <xsl:choose>
    <xsl:when test="$formtype = 'input'">
      <!-- If minOccurs = 0 then element is optional, it is not submitted if empty. -->
      <xsl:if test="@minOccurs = 0 or @use = 'optional' or @use = ''">
        <xsl:value-of>(. != '' or boolean-from-string(instance('temp')/relevant))</xsl:value-of>
      </xsl:if>
      <!-- If there ise relevant condition from previous choices, then add it. -->
      <xsl:if test="$relevant != ''">
        <xsl:value-of select="$relevant"/>
      </xsl:if>
      <!-- If element is part of choice, then make it relevant only when the choice is selected. -->
      <xsl:if test="$choiceref and $choiceid">
        <xsl:value-of>(../<xsl:value-of select="$choiceref"/> = '<xsl:value-of select="$choiceid"/>')</xsl:value-of>
      </xsl:if>
    </xsl:when>
    <xsl:when test="$formtype = 'output'">
      <!-- Suppress elements with xsi:nil=true on output forms. -->
      <xsl:if test="@nillable = 'true'">
        <xsl:value-of>not(boolean-from-string(if (@xsi:nil) then @xsi:nil else ''))</xsl:value-of>
      </xsl:if>
    </xsl:when>
    <xsl:otherwise>
      <xsl:message select="concat('Unknown formtype: ', $formtype)"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="xsd:element | xsd:attribute" mode="calculate">
  <xsl:if test="$debug"><xsl:message select="concat('calculate: ', name(), ', ', @name)"/></xsl:if>
</xsl:template>

<!-- Stop constraint generation when arrived to complex type. -->
<xsl:template match="xsd:complexType" mode="constraint"/>

<xsl:template match="xsd:minInclusive" mode="constraint">
  <xsl:if test="$debug"><xsl:message select="concat('constraint: ', name(), ', ', @value)"/></xsl:if>
  <xsl:value-of>. &gt;= <xsl:value-of select="if(../@base = 'xsd:date' and matches(@value, '^\d{4}-\d{2}-\d{2}$')) then concat('''', @value, '''') else @value"/></xsl:value-of>
</xsl:template>

<xsl:template match="xsd:maxInclusive" mode="constraint">
  <xsl:if test="$debug"><xsl:message select="concat('constraint: ', name(), ', ', @value)"/></xsl:if>
  <xsl:value-of>. &lt;= <xsl:value-of select="if(../@base = 'xsd:date' and matches(@value, '^\d{4}-\d{2}-\d{2}$')) then concat('''', @value, '''') else @value"/></xsl:value-of>
</xsl:template>

<xsl:template match="xsd:minExclusive" mode="constraint">
  <xsl:if test="$debug"><xsl:message select="concat('constraint: ', name(), ', ', @value)"/></xsl:if>
  <xsl:value-of>. &gt; <xsl:value-of select="if(../@base = 'xsd:date' and matches(@value, '^\d{4}-\d{2}-\d{2}$')) then concat('''', @value, '''') else @value"/></xsl:value-of>
</xsl:template>

<xsl:template match="xsd:maxExclusive" mode="constraint">
  <xsl:if test="$debug"><xsl:message select="concat('constraint: ', name(), ', ', @value)"/></xsl:if>
  <xsl:value-of>. &lt; <xsl:value-of select="if(../@base = 'xsd:date' and matches(@value, '^\d{4}-\d{2}-\d{2}$')) then concat('''', @value, '''') else @value"/></xsl:value-of>
</xsl:template>

<xsl:template match="xsd:length" mode="constraint">
  <xsl:if test="$debug"><xsl:message select="concat('constraint: ', name(), ', ', @value)"/></xsl:if>
  <xsl:value-of>string-length(.) = <xsl:value-of select="@value"/></xsl:value-of>
</xsl:template>

<xsl:template match="xsd:minLength" mode="constraint">
  <xsl:if test="$debug"><xsl:message select="concat('constraint: ', name(), ', ', @value)"/></xsl:if>
  <xsl:value-of>string-length(.) &gt;= <xsl:value-of select="@value"/></xsl:value-of>
</xsl:template>

<xsl:template match="xsd:maxLength" mode="constraint">
  <xsl:if test="$debug"><xsl:message select="concat('constraint: ', name(), ', ', @value)"/></xsl:if>
  <xsl:value-of>string-length(.) &lt;= <xsl:value-of select="@value"/></xsl:value-of>
</xsl:template>

<xsl:template match="xsd:pattern" mode="constraint">
  <xsl:if test="$debug"><xsl:message select="concat('constraint: ', name(), ', ', @value)"/></xsl:if>
  <xsl:choose>
    <!-- Orbeon cannot handle \xNUM and \uNUM characters so ignore restriction -->
    <xsl:when test="contains(@value, '\u') or contains(@value, '\x')">
        <xsl:value-of>'ignoring regex pattern constraint with \u or \x characters, because those cannot be handled by Orbeon'</xsl:value-of>
    </xsl:when>
    <xsl:otherwise>
        <xsl:value-of>matches(., '^<xsl:value-of select="replace(@value, '''', '''''')"/>$')</xsl:value-of>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="xsd:totalDigits" mode="constraint">
  <xsl:if test="$debug"><xsl:message select="concat('constraint: ', name(), ', ', @value)"/></xsl:if>
  <xsl:choose>
    <!-- If both totalDigits and fractionDigits exist. -->
    <xsl:when test="../xsd:fractionDigits/@value">
      <xsl:value-of>matches(., '^\d{1,<xsl:value-of select="@value - ../xsd:fractionDigits/@value"/>}(\.\d{1,<xsl:value-of select=" ../xsd:fractionDigits/@value"/>})?$')</xsl:value-of>
    </xsl:when>
    <!-- Only totalDigits. -->
    <xsl:otherwise>
      <xsl:value-of>matches(., '^\d{1,<xsl:value-of select="@value"/>}$')</xsl:value-of>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="xsd:fractionDigits" mode="constraint">
  <xsl:if test="$debug"><xsl:message select="concat('constraint: ', name(), ', ', @value)"/></xsl:if>
  <xsl:choose>
    <!-- If both totalDigits and fractionDigits exist then ignore. -->
    <!-- totalDigits template will generate the constraint. -->
    <xsl:when test="../xsd:totalDigits/@value"></xsl:when>
    <xsl:otherwise>
      <xsl:value-of>matches(., '^\d*(\.\d{1,<xsl:value-of select="@value"/>})?$')</xsl:value-of>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>
 
<!-- Form generation. -->

<xsl:template match="xsd:complexType" mode="form">
  <xsl:param name="node" tunnel="yes" />
  <xsl:param name="ref" tunnel="yes"/>
  <xsl:param name="parentref" tunnel="yes"/>
  <xsl:param name="tnsprefix" tunnel="yes"/>
  <xsl:param name="usenamespace" tunnel="yes"/>
  <xsl:if test="$debug"><xsl:message select="concat('form: ', name(), ', ', @name)"/></xsl:if>
  <xsl:choose>
    <!-- If ref = '.', then don't create group, repeat has already been created. -->
    <xsl:when test="$ref = '.'">
      <!-- Generate subfields. -->
      <xsl:apply-imports/>
    </xsl:when>
    <xsl:otherwise>
  	  <xsl:variable name="usenamespace" select="$usenamespace or ancestor::xsd:schema/@elementFormDefault='qualified'" />
	  <xsl:variable name="ref" select="
	  if ($usenamespace and not(contains($ref, ':'))) 
	  then concat($tnsprefix, ':', $ref) 
	  else $ref" />
      <xforms:group ref="{$ref}">
        <xsl:if test="$usenamespace">
          <xsl:namespace name="{$tnsprefix}" select="ancestor::xsd:schema/@targetNamespace"/>
        </xsl:if>
        <!-- Generate labels and hints. -->
        <xsl:if test="$node">
          <xsl:apply-templates select="$node" mode="label-only"/>
        </xsl:if>
        <!-- Generate subfields. -->
        <xsl:apply-imports>
          <xsl:with-param name="element" tunnel="yes"/>
          <xsl:with-param name="ref" select="'.'" tunnel="yes"/>
          <xsl:with-param name="parentref" select="concat($parentref, '/', $ref)" tunnel="yes"/>
        </xsl:apply-imports>
      </xforms:group>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="xsd:sequence" mode="form">
  <xsl:if test="$debug"><xsl:message select="concat('form: ', name())"/></xsl:if>
  <xsl:apply-imports>
    <xsl:with-param name="maxOccurs" select="@maxOccurs" tunnel="yes"/>
  </xsl:apply-imports>  
</xsl:template>

<xsl:template match="xsd:element" mode="form">
  <xsl:param name="ref" tunnel="yes"/>
  <xsl:param name="element" tunnel="yes"/>
  <xsl:param name="parentref" tunnel="yes"/>
  <xsl:param name="formname" tunnel="yes" />
  <xsl:param name="formtype" tunnel="yes" />
  <xsl:param name="maxOccurs" tunnel="yes" />
  <xsl:param name="tnsprefix" tunnel="yes" />
  <xsl:param name="usenamespace" tunnel="yes" />
  <xsl:param name="nestedRepeats" tunnel="yes" />
  <xsl:if test="$debug"><xsl:message select="concat('form: ', name(), ', ', @name)"/></xsl:if>
  <xsl:variable name="usenamespace" select="$usenamespace or ancestor::xsd:schema/@elementFormDefault='qualified'" />
  <xsl:variable name="newref" select="concat(if ($usenamespace) then concat($tnsprefix, ':') else '', normalize-space(if ($element) then $element else @name))"/>
  <xsl:variable name="newparentref" select="if ($ref = '.') then $parentref else concat($parentref, '/', $ref)"/>
  <xsl:variable name="newfullref" select="concat($newparentref,'/', $newref)"/>
  <xsl:variable name="maxOccurs" select="if (@maxOccurs) then @maxOccurs else if ($maxOccurs) then $maxOccurs else '1'"/>
  <xsl:choose>
    <!-- If maxOccurs > 1, then create repeat block. -->
    <xsl:when test="$maxOccurs = 'unbounded' or number($maxOccurs) &gt; 1">
      <xsl:variable name="repeat-id" select="translate(concat($formname, '_', $formtype, $newfullref),'():/.*''','_______')"/>
      <xforms:repeat nodeset="{$newref}" id="{$repeat-id}" >
        <xsl:if test="$usenamespace">
          <xsl:namespace name="{$tnsprefix}" select="ancestor::xsd:schema/@targetNamespace"/>
        </xsl:if>

        <!-- Count nested repeats repeats and decide whether to show full table -->
        <xsl:variable name="nestedRepeats" select="if (not($nestedRepeats)) then 0 else $nestedRepeats" />
        <xsl:variable name="hasNestedSubelements" select=".[.//xsd:element[starts-with(@type, concat($tnsprefix, ':')) or .//xsd:element]]"/>
        <xsl:variable name="increaseNestedRepeatCount" select="$hasNestedSubelements or number($nestedRepeats) &gt; 0" />
        <xsl:variable name="nestedRepeats" select="if ($increaseNestedRepeatCount) then number($nestedRepeats) + 1 else $nestedRepeats" />
        <xsl:if test="number($nestedRepeats) &gt; 0">
           <xsl:choose>
             <xsl:when test=".[xsd:annotation/xsd:appinfo or starts-with(@type, concat($tnsprefix, ':'))]">
               <!-- If there are element labels, add label-value pairs to full appearance table -->
               <xsl:attribute name="appearance">full</xsl:attribute>
             </xsl:when>
             <xsl:otherwise>
               <!-- If no element label, add text in a row --> 
               <xsl:attribute name="appearance">minimal</xsl:attribute>
             </xsl:otherwise>
           </xsl:choose>
           <xsl:attribute name="class">is-nested</xsl:attribute>
           <!-- debug: <xsl:attribute name="data-nested" select="$nestedRepeats"></xsl:attribute> -->
        </xsl:if>
        <!-- Generate labels and hints. -->
        <!-- Repeat can't have a label, although Chiba renders it correctly. -->
        <!--xsl:apply-templates select="." mode="label"/-->
        <xsl:apply-templates select="xsd:annotation" mode="appearance"/>
        <!-- Generate children. -->
        <xsl:apply-imports>
          <xsl:with-param name="node" select="." tunnel="yes"/>
          <xsl:with-param name="element" tunnel="yes"/>
          <xsl:with-param name="ref" select="'.'" tunnel="yes"/>
          <xsl:with-param name="parentref" select="$newfullref" tunnel="yes"/>
          <xsl:with-param name="maxOccurs" tunnel="yes"/>
          <xsl:with-param name="usenamespace" tunnel="yes"/>
          <xsl:with-param name="nestedRepeats" select="$nestedRepeats" tunnel="yes"/>
        </xsl:apply-imports>
      </xforms:repeat>
      <xsl:if test="$formtype = 'input'">
        <xforms:group class="repeat-actions" appearance="minimal">
          <xforms:trigger ref=".[count({$newref}) - 1 &lt; {if ($maxOccurs = 'unbounded') then 1000 else $maxOccurs}]">
            <xsl:apply-templates select="." mode="form-repeat-insert-label"/>
            <xforms:insert events:event="DOMActivate" nodeset="{$newref}" at="last()" position="before"/>
          </xforms:trigger>
          <xforms:trigger ref=".[count({$newref}) - 1 &gt; {if (exists(@minOccurs)) then @minOccurs else 1}]">
            <xsl:apply-templates select="." mode="form-repeat-delete-label"/>
            <xforms:delete events:event="DOMActivate" nodeset="{$newref}" at="index('{$repeat-id}')"/>
            <!-- Set position to next item, but not on prototype item. You wouldn't want to delete that. -->
            <xforms:setindex events:event="DOMActivate" repeat="{$repeat-id}" index="if (index('{$repeat-id}') = count({$newref})) then index('{$repeat-id}') - 1 else index('{$repeat-id}')"/>
          </xforms:trigger>
        </xforms:group>
      </xsl:if>
    </xsl:when>
    <xsl:otherwise>
      <xsl:apply-imports>
        <xsl:with-param name="node" select="." tunnel="yes"/>
        <xsl:with-param name="element" tunnel="yes"/>
        <xsl:with-param name="ref" select="$newref" tunnel="yes"/>
        <xsl:with-param name="parentref" select="$newparentref" tunnel="yes"/>
        <xsl:with-param name="maxOccurs" tunnel="yes"/>
        <xsl:with-param name="usenamespace" tunnel="yes"/>
      </xsl:apply-imports>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="xsd:element" mode="form-repeat-insert-label">
  <xforms:label>Insert</xforms:label>
</xsl:template>

<xsl:template match="xsd:element" mode="form-repeat-delete-label">
  <xforms:label>Delete</xforms:label>
</xsl:template>

<xsl:template match="xsd:attribute" mode="form">
  <xsl:param name="ref" tunnel="yes"/>
  <xsl:param name="parentref" tunnel="yes"/>
  <xsl:if test="$debug"><xsl:message select="concat('form: ', name(), ', ', @name)"/></xsl:if>
  <xsl:apply-imports>
    <xsl:with-param name="node" select="." tunnel="yes"/>
    <xsl:with-param name="ref" select="concat('@', @name)" tunnel="yes"/>
    <xsl:with-param name="parentref" select="if ($ref = '.') then $parentref else concat($parentref, '/', $ref)" tunnel="yes"/>
  </xsl:apply-imports>
</xsl:template>

<!-- If there is a list then generate select control. -->
<xsl:template match="xsd:list" mode="form">
  <xsl:param name="node" tunnel="yes"/>
  <xsl:param name="ref" tunnel="yes"/>
  <xsl:param name="formtype" tunnel="yes"/>
  <xsl:choose>
    <xsl:when test="$formtype = 'input'">
      <xforms:select ref="{$ref}">
        <!-- Generate labels and hints. -->
        <xsl:apply-templates select="$node" mode="label"/>
        <!-- Orbeon does not add empty choice automatically, add it here. -->
        <xforms:item>
          <xforms:label/>
          <xforms:value/>
        </xforms:item>
        <!-- Generate enumeration list. -->
        <xsl:apply-templates select="." mode="itemset"/>
      </xforms:select>
    </xsl:when>
    <xsl:otherwise>
      <xsl:apply-imports/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="xsd:restriction" mode="form">
  <xsl:param name="node" tunnel="yes"/>
  <xsl:param name="ref" tunnel="yes"/>
  <xsl:param name="formtype" tunnel="yes"/>
  <xsl:choose>
    <xsl:when test="$formtype = 'input'">
      <xsl:choose>
        <!-- If there is a enumeration then generate select1 control. -->
        <xsl:when test="xsd:enumeration">
          <xforms:select1 ref="{$ref}">
            <!-- Generate labels and hints. -->
            <xsl:apply-templates select="$node" mode="label"/>
            <!-- Orbeon does not add empty choice automatically, add it here. -->
            <xforms:item>
              <xforms:label/>
              <xforms:value/>
            </xforms:item>
            <!-- Generate enumeration list. -->
            <xsl:apply-templates select="." mode="itemset"/>
          </xforms:select1>
        </xsl:when>
        <!-- If there is minInclusive and maxExclusive restriction then generate range control. -->
        <xsl:when test="xsd:minInclusive and xsd:maxInclusive and false()">
          <xforms:range ref="{$ref}" start="{xsd:minInclusive/@value}" end="{xsd:maxInclusive/@value}">
            <!-- Generate labels and hints. -->
            <xsl:apply-templates select="$node" mode="label"/>
          </xforms:range>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-imports/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="$formtype = 'output'">
      <xsl:choose>
        <!-- If there is enumeration inside then use label instead of value. -->
        <xsl:when test="xsd:enumeration">
          <xforms:group ref="{$ref}">
            <!-- Generate labels and hints. -->
            <xsl:apply-templates select="$node" mode="label"/>
            <xforms:output value="instance('lookup-{generate-id()}')/item[@value = current()]"/>
          </xforms:group>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-imports/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
  </xsl:choose>
</xsl:template>

<xsl:template match="xsd:restriction" mode="itemset">
  <xforms:itemset nodeset="instance('lookup-{generate-id()}')/item">
    <xforms:label ref="."/>
    <xforms:value ref="@value"/>
  </xforms:itemset>
</xsl:template>

<xsl:template match="/" mode="form">
  <xsl:param name="name"/>
  <xsl:param name="what"/>
  <xsl:param name="context"/>
  <xsl:param name="node" tunnel="yes"/>
  <xsl:param name="ref" tunnel="yes"/>
  <xsl:param name="formtype" tunnel="yes"/>

  <xsl:if test="$debug"><xsl:message select="concat('createControl: ', $name, ', ', $what, ', ', $formtype)"/></xsl:if>

  <xsl:variable name="qname" select="resolve-QName($name, $context)"/>
  <xsl:variable name="localname" select="local-name-from-QName($qname)"/>
  <xsl:variable name="namespace" select="namespace-uri-from-QName($qname)"/>

  <xsl:choose>
    <!-- If trying to resolve type and it is schema type. -->
    <xsl:when test="ends-with($what, 'Type') and $namespace = 'http://www.w3.org/2001/XMLSchema'">
      <xsl:choose>
        <!-- Input form controls. -->
        <xsl:when test="$formtype = 'input'">
          <xsl:choose>
            <xsl:when test="$localname = ('base64Binary', 'hexBinary')">
              <xforms:upload ref="{$ref}">
                <!-- Generate labels and hints. -->
                <xsl:apply-templates select="$node" mode="label"/>
                <xforms:filename ref="@filename"/>
              </xforms:upload>
            </xsl:when>
            <xsl:otherwise>
              <xforms:input ref="{$ref}">
                <!-- Generate labels and hints. -->
                <xsl:apply-templates select="$node" mode="label"/>
              </xforms:input>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <!-- Output form controls. -->
        <xsl:when test="$formtype = 'output'">
          <xsl:choose>
            <xsl:when test="$localname = ('base64Binary', 'hexBinary')">
        	  <!-- Use xxforms:download appearance to display download link, style to group on the same page-->
              <xforms:group appearance="minimal" style="display:inline;">
	              <xforms:output ref="{$ref}" appearance="xxforms:download">
<!-- 			       This would result in always generating 'Download named links' -->
<!-- 			           <xforms:label xml:lang="et">Laadi alla</xforms:label> -->
<!-- 			           <xforms:label xml:lang="en">Download</xforms:label> -->
<!-- 			           <xforms:label xml:lang="ru">Скачать</xforms:label> -->

			           <!-- Add default labels for download element, if labels do not exist. -->
			           <!-- The following adds default labels to empty-named fields only-->
			           
			           <xsl:if test="not($node/xsd:annotation/xsd:appinfo/*[@xml:lang='et']) or normalize-space($node/xsd:annotation/xsd:appinfo/*[@xml:lang='et']) = ''">
			           		<xforms:label xml:lang="et">Laadi alla</xforms:label>
			           </xsl:if>
			           <xsl:if test="not($node/xsd:annotation/xsd:appinfo/*[@xml:lang='en']) or normalize-space($node/xsd:annotation/xsd:appinfo/*[@xml:lang='et']) = ''">
			           		<xforms:label xml:lang="en">Download</xforms:label>
			           </xsl:if>
			           <xsl:if test="not($node/xsd:annotation/xsd:appinfo/*[@xml:lang='ru']) or normalize-space($node/xsd:annotation/xsd:appinfo/*[@xml:lang='et']) = ''">
			           		<xforms:label xml:lang="ru">Скачать</xforms:label>
			           </xsl:if>
			           
			           <!-- Generate labels and hints. -->
			           <xsl:apply-templates select="$node" mode="label"/>
			           
			           <xforms:hint xml:lang="et" value="concat(
			           		if(@filename | ../filename) then concat('Faili nimetus: ', @filename | ../filename) else '', 
			           		if(@size) then concat(', suurus: ', @size, ' B') else '')" />
			           	
			           <xforms:hint xml:lang="en" value="concat(
			           		if(@filename | ../filename) then concat('File name: ', @filename | ../filename) else '', 
			           		if(@size) then concat(', size: ', @size, ' B') else '')" />
			           	
			           <xforms:hint xml:lang="ru" value="concat(
			           		if(@filename | ../filename) then concat('Имя файла: ', @filename | ../filename) else '', 
			           		if(@size) then concat('размер: ', @size, ' B') else '')" />
			           	
			           
					   <xforms:filename ref="@filename | ../filename"/>
	              </xforms:output>
              </xforms:group>
            </xsl:when>
            <xsl:otherwise>
              <xforms:output ref="{$ref}">
                <!-- Generate labels and hints. -->
                <xsl:apply-templates select="$node" mode="label"/>
              </xforms:output>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>
      <!-- Try to resolve the name. -->
      <xsl:apply-imports>
        <xsl:with-param name="name" select="$name"/>
        <xsl:with-param name="what" select="$what"/>
        <xsl:with-param name="context" select="$context"/>
      </xsl:apply-imports>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="xsd:choice" mode="form">
  <xsl:param name="formtype" tunnel="yes"/>
  <xsl:if test="$debug"><xsl:message select="concat('form: ', name())"/></xsl:if>
  <xsl:choose>
    <xsl:when test="$formtype = 'input'">
      <xforms:group>
        <xsl:variable name="choiceref" select="concat('choice-', generate-id())"/>
        <xforms:select1 ref="{$choiceref}" appearance="full">
          <xsl:apply-templates mode="choice">
            <xsl:with-param name="choiceref" select="$choiceref" tunnel="yes" />
          </xsl:apply-templates>
        </xforms:select1>
        <xsl:apply-imports />
      </xforms:group>
    </xsl:when>
    <xsl:otherwise>
      <xsl:apply-imports />
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="xsd:element | xsd:group | xsd:choice | xsd:sequence" mode="choice">
  <xsl:if test="$debug"><xsl:message select="concat('choice: ', name(), ', ', @name)"/></xsl:if>
  <xforms:item>
    <xforms:value><xsl:value-of select="generate-id()"/></xforms:value>
    <xsl:apply-templates select='*[1]' mode="label-only"/>
  </xforms:item>
</xsl:template>

<!-- label mode will add appearance attributes too, while title, heading and label-only don't. -->
<xsl:template match="xsd:element | xsd:attribute | xsd:group | xsd:enumeration" mode="label">
  <xsl:apply-templates select="xsd:annotation" mode="appearance"/>
  <xsl:call-template name="process-labels"/>
</xsl:template>

<xsl:template match="xsd:element | xsd:attribute | xsd:group | xsd:enumeration" mode="title heading label-only" name="process-labels">
  <xsl:if test="$debug"><xsl:message select="concat('label: ', name(), ', ', @name, ', ', @value)"/></xsl:if>
  <!-- label -->
  <xsl:variable name="label">
    <!-- Check xsd:annotation for label. -->
    <dummy>
      <xsl:apply-templates select="xsd:annotation" mode="#current"/>
    </dummy>
  </xsl:variable>
  <xsl:choose>
    <xsl:when test="exists($label/dummy/@* | $label/dummy/*)">
      <!-- If found something in xsd:annotation, then use that. -->
      <xsl:copy-of select="$label/dummy/@* | $label/dummy/*"/>
    </xsl:when>
    <xsl:otherwise>
      <!-- Otherwise use label of type or referenced element. -->
      <xsl:apply-imports />
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="xsd:simpleType | xsd:complexType" mode="label title heading label-only">
  <!-- Don't descend further from simpleType or complexType. -->
  <xsl:apply-templates select="xsd:annotation" mode="#current"/>
</xsl:template>

<xsl:template match="xsd:annotation" mode="appearance">
  <xsl:if test="$debug"><xsl:message select="concat('label: ', name())"/></xsl:if>
  <xsl:if test="@xforms:appearance">
    <xsl:attribute name="appearance" select="@xforms:appearance"/>
  </xsl:if>
  <xsl:if test="@xforms:incremental">
    <xsl:attribute name="incremental" select="@xforms:incremental"/>
  </xsl:if>
  <xsl:if test="@xforms:inputmode">
    <xsl:attribute name="inputmode" select="@xforms:inputmode"/>
  </xsl:if>
  <xsl:if test="@xforms:selection">
    <xsl:attribute name="selection" select="@xforms:selection"/>
  </xsl:if>
  <xsl:apply-imports/>
</xsl:template>

<xsl:template match="xforms:label" mode="label label-only">
  <xsl:if test="$debug"><xsl:message select="concat('label-only: ', name())"/></xsl:if>
  <xsl:copy-of select="." copy-namespaces="no"/>
</xsl:template>

<xsl:template match="xforms:hint | xforms:help | xforms:alert" mode="label">
  <xsl:if test="$debug"><xsl:message select="concat('label: ', name())"/></xsl:if>
  <xsl:copy-of select="." copy-namespaces="no"/>
</xsl:template>

<xsl:template match="xsd:documentation" mode="label label-only">
  <xsl:if test="$debug"><xsl:message select="concat('label: ', name())"/></xsl:if>
  <xforms:label><xsl:value-of select="."/></xforms:label>
</xsl:template>

<xsl:template match="xsd:documentation" mode="title">
  <xsl:if test="$debug"><xsl:message select="concat('title: ', name())"/></xsl:if>
  <xhtml:title><xsl:value-of select="."/></xhtml:title>
</xsl:template>

<xsl:template match="xsd:documentation" mode="heading">
  <xsl:if test="$debug"><xsl:message select="concat('heading: ', name())"/></xsl:if>
  <xhtml:h1><xsl:value-of select="."/></xhtml:h1>
</xsl:template>

</xsl:stylesheet>
