<xsl:stylesheet version="1.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <!-- A rough and ready XSL transform from Tagged PDF XML serialization to HTML -->
  <xsl:template match="/Document|/DocumentFragment">
    <html>
      <head>
      </head>
      <body>
        <xsl:apply-templates/>
      </body>
    </html>
  </xsl:template>
  <xsl:template match="Link[@href]">
    <!-- /Link href="xxx" -> a href="xxx" -->
    <a>
      <xsl:apply-templates select="@*|node()"/>
    </a>
  </xsl:template>
  <xsl:template match="@SpaceBefore">
    <xsl:attribute name="style">
      <xsl:value-of select="concat('margin-top:', ., 'pt;')" />
    </xsl:attribute>
  </xsl:template>
  <xsl:template match="@SpaceAfter">
    <xsl:attribute name="style">
      <xsl:value-of select="concat('margin-bottom:', ., 'pt;')" />
    </xsl:attribute>
  </xsl:template>
  <xsl:template match="@ColumnSpan">
    <xsl:attribute name="colspan">
      <xsl:value-of select="." />
    </xsl:attribute>
  </xsl:template>
  <xsl:template match="L/LI/Lbl">
    <!-- Discard superflous Lbl tags in list items -->
  </xsl:template>

  <xsl:template match="L[@role='DL']">
    <dl><xsl:apply-templates/></dl>
  </xsl:template>

  <xsl:template match="Lbl[@role='DT']">
    <dt><xsl:apply-templates/></dt>
  </xsl:template>

  <xsl:template match="LBody[@role='DD']">
    <dd><xsl:apply-templates/></dd>
  </xsl:template>

  <xsl:template match="LI[@role='DL-DIV']">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="L">
    <ul>
      <xsl:apply-templates/>
    </ul>
  </xsl:template>

  <xsl:template match="Span[@TextDecorationType='Underline']">
    <!-- underline -->
    <u>
       <xsl:apply-templates/>
    </u>
  </xsl:template>
  <xsl:template match="TOC|DocumentFragment|Formula|Form|Part|Art|Sect|Index|FENote|Note">
    <!-- currently omitted block tags -->
    <div>
      <xsl:attribute name="class">
        <xsl:value-of select="name(.)"/>
      </xsl:attribute>
      <xsl:apply-templates/>
    </div>
  </xsl:template>
  <xsl:template match="Artifact|Reference|RB|RT|Warichu|RP|RT|TagSuspect|ReversedChars|Clip|BibEntry|Annot|Link|LBody|TOCI">
    <!-- currently ignored inline tags -->
    <span>
      <xsl:attribute name="class">
        <xsl:value-of select="name(.)"/>
      </xsl:attribute>
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  <xsl:template match="Mark">
    <!-- marked content region -->
    <xsl:value-of select=".//text()"/>
  </xsl:template>
  <xsl:template match="@*|node()">
    <!-- Identity transform -->
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
