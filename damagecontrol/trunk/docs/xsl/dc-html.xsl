<?xml version="1.0"?>
<!DOCTYPE xsl:stylesheet [

<!ENTITY lowercase "'abcdefghijklmnopqrstuvwxyz'">
<!ENTITY uppercase "'ABCDEFGHIJKLMNOPQRSTUVWXYZ'">

<!ENTITY primary   'normalize-space(concat(primary/@sortas, primary[not(@sortas)]))'>
<!ENTITY secondary 'normalize-space(concat(secondary/@sortas, secondary[not(@sortas)]))'>
<!ENTITY tertiary  'normalize-space(concat(tertiary/@sortas, tertiary[not(@sortas)]))'>

<!ENTITY section   '(ancestor-or-self::set
                     |ancestor-or-self::book
                     |ancestor-or-self::part
                     |ancestor-or-self::reference
                     |ancestor-or-self::partintro
                     |ancestor-or-self::chapter
                     |ancestor-or-self::appendix
                     |ancestor-or-self::preface
                     |ancestor-or-self::article
                     |ancestor-or-self::section
                     |ancestor-or-self::sect1
                     |ancestor-or-self::sect2
                     |ancestor-or-self::sect3
                     |ancestor-or-self::sect4
                     |ancestor-or-self::sect5
                     |ancestor-or-self::refentry
                     |ancestor-or-self::refsect1
                     |ancestor-or-self::refsect2
                     |ancestor-or-self::refsect3
                     |ancestor-or-self::simplesect
                     |ancestor-or-self::bibliography
                     |ancestor-or-self::glossary
                     |ancestor-or-self::index
                     |ancestor-or-self::webpage)[last()]'>

<!ENTITY section.id 'generate-id(&section;)'>
<!ENTITY sep '" "'>
<!ENTITY scope 'count(ancestor::node()|$scope) = count(ancestor::node())'>
]>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:import href="/usr/share/sgml/docbook/xsl-stylesheets-1.65.1/html/chunk.xsl"/>
	
	<xsl:param name="damagecontrol.version">0.4-alpha-dev</xsl:param>
	
	<xsl:param name="suppress.footer.navigation">1</xsl:param>
	<xsl:param name="suppress.header.navigation">1</xsl:param>
	<xsl:param name="suppress.navigation">1</xsl:param>
	
	<xsl:template name="user.head.content">
		<xsl:param name="node" select="."/>
		
		<link rel="stylesheet" href="css/style.css" type="text/css" />
		<link rel="stylesheet" href="css/color.css" type="text/css" />
		<script type="text/javascript" src="index.js">
			<xsl:text> </xsl:text>
		</script>
	</xsl:template>
	
	<xsl:template name="user.header.navigation">
		<xsl:param name="node" select="."/>
		
		<table nowrap="nowrap" class="pane">

			<tr>
				<td class="pane-header">
      Table of Contents
    </td>
			</tr>
  
<!-- 

(preceding-sibling::set
|preceding-sibling::book
|preceding-sibling::part
|preceding-sibling::reference
|preceding-sibling::partintro
|preceding-sibling::chapter
|preceding-sibling::appendix
|preceding-sibling::preface
|preceding-sibling::article
|preceding-sibling::section
|preceding-sibling::sect1
|preceding-sibling::sect2
|preceding-sibling::sect3
|preceding-sibling::sect4
|preceding-sibling::sect5
|preceding-sibling::refentry
|preceding-sibling::refsect1
|preceding-sibling::refsect2
|preceding-sibling::refsect3
|preceding-sibling::simplesect
|preceding-sibling::bibliography
|preceding-sibling::glossary
|preceding-sibling::index
|preceding-sibling::webpage)

-->

			<xsl:for-each select="(preceding-sibling::set |preceding-sibling::book |preceding-sibling::part |preceding-sibling::reference |preceding-sibling::partintro |preceding-sibling::chapter |preceding-sibling::appendix |preceding-sibling::preface |preceding-sibling::article |preceding-sibling::section |preceding-sibling::sect1 |preceding-sibling::sect2 |preceding-sibling::sect3 |preceding-sibling::sect4 |preceding-sibling::sect5 |preceding-sibling::refentry |preceding-sibling::refsect1 |preceding-sibling::refsect2 |preceding-sibling::refsect3 |preceding-sibling::simplesect |preceding-sibling::bibliography |preceding-sibling::glossary |preceding-sibling::index |preceding-sibling::webpage)">
				<tr class="build-row">
					<td nowrap="nowrap">
						<img width="16" height="16" src="images/green-16.gif" style="margin-right:10px;"/>
						<a class="tip">
							<xsl:attribute name="href">
								<xsl:call-template name="href.target">
									<xsl:with-param name="object" select="."/>
								</xsl:call-template>
							</xsl:attribute>
							<xsl:apply-templates select="." mode="object.title.markup"/>
						</a>
					</td>
				</tr>
			</xsl:for-each>
	
			<tr class="build-row">
				<td nowrap="nowrap">
					<img width="16" height="16" src="images/green-16.gif" style="margin-right:10px;" />
					<span class="highlighted-build">
						<a class="tip">
							<xsl:attribute name="href">
								<xsl:call-template name="href.target">
									<xsl:with-param name="object" select="."/>
								</xsl:call-template>
							</xsl:attribute>
							<b>
								<xsl:apply-templates select="." mode="object.title.markup"/>
							</b>
						</a>
					</span>
				</td>
			</tr>
	
			<xsl:for-each select="(child::set |child::book |child::part |child::reference |child::partintro |child::chapter |child::appendix |child::preface |child::article |child::section |child::sect1 |child::sect2 |child::sect3 |child::sect4 |child::sect5 |child::refentry |child::refsect1 |child::refsect2 |child::refsect3 |child::simplesect |child::bibliography |child::glossary |child::index |child::webpage)">
				<tr class="build-row">
					<td nowrap="nowrap">
						<img width="16" height="16" src="images/red-16.gif" style="margin-right:10px;"/>
						<a class="tip">
							<xsl:attribute name="href">
								<xsl:call-template name="href.target">
									<xsl:with-param name="object" select="."/>
								</xsl:call-template>
							</xsl:attribute>
							<xsl:apply-templates select="." mode="object.title.markup"/>
						</a>
					</td>
				</tr>
			</xsl:for-each>
	
			<xsl:for-each select="(following-sibling::set |following-sibling::book |following-sibling::part |following-sibling::reference |following-sibling::partintro |following-sibling::chapter |following-sibling::appendix |following-sibling::preface |following-sibling::article |following-sibling::section |following-sibling::sect1 |following-sibling::sect2 |following-sibling::sect3 |following-sibling::sect4 |following-sibling::sect5 |following-sibling::refentry |following-sibling::refsect1 |following-sibling::refsect2 |following-sibling::refsect3 |following-sibling::simplesect |following-sibling::bibliography |following-sibling::glossary |following-sibling::index |following-sibling::webpage)">
				<tr class="build-row">
					<td nowrap="nowrap">
						<img width="16" height="16" src="images/green-16.gif" style="margin-right:10px;"/>
						<a class="tip">
							<xsl:attribute name="href">
								<xsl:call-template name="href.target">
									<xsl:with-param name="object" select="."/>
								</xsl:call-template>
							</xsl:attribute>
							<xsl:apply-templates select="." mode="object.title.markup"/>
						</a>
					</td>
				</tr>
			</xsl:for-each>
		</table>

	
	</xsl:template>
	
	
	<xsl:template name="header.navigation">
		<xsl:param name="prev" select="/foo"/>
		<xsl:param name="next" select="/foo"/>
		<xsl:param name="nav.context"/>
		
		<xsl:variable name="home" select="/*[1]"/>
		<xsl:variable name="up" select="parent::*"/>

		<div id="tasks">
			<xsl:if test="count($prev)>0">
				<div class="task">
					<a>
						<xsl:attribute name="href">
							<xsl:call-template name="href.target">
								<xsl:with-param name="object" select="$prev"/>
							</xsl:call-template>
						</xsl:attribute>
						<img width="24" height="24" src="largeicons/navigate_left.png"/>
					</a>
					<a accesskey="p" title="Alt+P" class="navigator">
						<xsl:attribute name="href">
							<xsl:call-template name="href.target">
								<xsl:with-param name="object" select="$prev"/>
							</xsl:call-template>
						</xsl:attribute>
						<xsl:apply-templates select="$prev" mode="object.title.markup"/>
					</a>
				</div>
			</xsl:if>
			
			<xsl:if test="count($next)>0">
				<div class="task">
					<a>
						<xsl:attribute name="href">
							<xsl:call-template name="href.target">
								<xsl:with-param name="object" select="$next"/>
							</xsl:call-template>
						</xsl:attribute>
						<img width="24" height="24" src="largeicons/navigate_right.png"/>
					</a>
					<a accesskey="n" title="Alt+N" class="navigator">
						<xsl:attribute name="href">
							<xsl:call-template name="href.target">
								<xsl:with-param name="object" select="$next"/>
							</xsl:call-template>
						</xsl:attribute>
						<xsl:apply-templates select="$next" mode="object.title.markup"/>
					</a>
				</div>
			</xsl:if>

		</div>
	</xsl:template>
	
	
	
	<xsl:template name="chunk-element-content">
		<xsl:param name="prev"/>
		<xsl:param name="next"/>
		<xsl:param name="nav.context"/>
		<xsl:param name="content">
			<xsl:apply-imports/>
		</xsl:param>
		
		<html>
			<xsl:call-template name="html.head">
				<xsl:with-param name="prev" select="$prev"/>
				<xsl:with-param name="next" select="$next"/>
			</xsl:call-template>
			
			<body>
				<xsl:call-template name="body.attributes"/>
				
				<xsl:call-template name="user.header.content"/>
				
				
				<table id="main-table" width="100%" height="70%" border="0">
					<tr>

						<td id="side-panel" width="20%">
	
							<xsl:call-template name="header.navigation">
								<xsl:with-param name="prev" select="$prev"/>
								<xsl:with-param name="next" select="$next"/>
								<xsl:with-param name="nav.context" select="$nav.context"/>
							</xsl:call-template>

							<div id="navigation">
								<xsl:call-template name="user.header.navigation"/>
							</div>
						</td>
						<td id="main-panel" width="80%" height="100%">
							<h1 class="pane">
								<xsl:apply-templates select="." mode="object.title.markup"/>
							</h1>
							<div style="padding-top: 5px">
								<ul id="foldertab">
									<li>
										<a href="#" id="current">	<img src="smallicons/help.png" style="margin-right:10px;"/>Help</a>
									</li>
								</ul>
							</div>
							<table class="pane">
								<tr>
									<td colspan="3">
										<xsl:copy-of select="$content"/>
									</td>
								</tr>
							</table>
						</td>
					</tr>
					<tr>
						<td id="footer" colspan="2" background="images/footer_grad.gif">
							<xsl:call-template name="user.footer.content"/>
						</td>
					</tr>
				</table>
				<xsl:call-template name="footer.navigation">
					<xsl:with-param name="prev" select="$prev"/>
					<xsl:with-param name="next" select="$next"/>
					<xsl:with-param name="nav.context" select="$nav.context"/>
				</xsl:call-template>
				<xsl:call-template name="user.footer.navigation"/>
			</body>
		</html>
	</xsl:template>
	
	
	<xsl:template name="user.header.content">
		<xsl:param name="node" select="."/>
		
		<xsl:variable name="home" select="/*[1]"/>
		<xsl:variable name="up" select="parent::*"/>
		
		<table id="header" cellpadding="0" cellspacing="0" width="100%" border="0">
			
			<tr id="top-panel">
				<td>
					<a href="http://damagecontrol.codehaus.org/">
						<img class="logo" src="images/damagecontrol-logo.gif"/>
					</a>
				</td>
				<td align="right" valign="bottom" style="vertical-align: bottom;">
					<a href="http://www.thoughtworks.com/">
						<img class="logo" src="images/tw-logo.png"/>
					</a>
					<form onsubmit="go();return false;" id="indexseachform">
						<div id="searchform">
							<img width="24" height="24" src="largeicons/find.png"/>
							<b>Search:</b>
							<input id="searchterm" onkeyup="showmatches()" name="search" size="12" autocomplete="off"/>
							<input type="submit" value="Go"/>
							<div id="resultate">
							</div>
						</div>
					</form>
				</td>
			</tr>
			<tr id="top-nav">
				<td id="left-top-nav">
					<!-- navigation -->
					<a accesskey="h" title="Alt+H" class="navigator">
						<xsl:attribute name="href">
							<xsl:call-template name="href.target">
								<xsl:with-param name="object" select="$home"/>
							</xsl:call-template>
						</xsl:attribute>
						<xsl:apply-templates select="$home" mode="object.title.markup"/>
					</a>
					<xsl:if test="count($up) &gt; 0 and $up != $home">
						&gt;
						<a accesskey="u" title="Alt+U" class="navigator">
						<xsl:attribute name="href">
							<xsl:call-template name="href.target">
								<xsl:with-param name="object" select="$up"/>
								</xsl:call-template>
							</xsl:attribute>
							<xsl:apply-templates select="$up" mode="object.title.markup"/>
						</a>
					</xsl:if>
					<xsl:if test="$home!=.">
						&gt;
						<a class="navigator">
							<xsl:attribute name="href">
								<xsl:call-template name="href.target">
									<xsl:with-param name="object" select="."/>
								</xsl:call-template>
							</xsl:attribute>
							<xsl:apply-templates select="." mode="object.title.markup"/>
						</a>
					</xsl:if>
				</td>
				<td id="right-top-nav">
				<!--
					<span class="smallfont">
					REFRESH: 
					<a href="http://sources.goshaky.com/public/project?project_name=xdb&amp;auto_refresh=true">ON</a> | <span class="redbold">OFF</span>
					</span>
				--></td>
			</tr>
		</table>
	</xsl:template>
	
	<xsl:template name="user.footer.content">
		<xsl:param name="node" select="."/>
		This stuff displays best in a Mozilla based browser. Try <a href="http://www.mozilla.org/products/firefox/">Firefox</a>.
		<br />
		<a href="http://damagecontrol.codehaus.org">DamageControl version <xsl:value-of select="$damagecontrol.version"/>
		</a>
	</xsl:template>
	
	<xsl:template name="user.footer.navigation">
		<xsl:param name="node" select="."/>
	</xsl:template>
	
	
	<!-- Javascript Suggest Index -->
	
	<xsl:template name="body.attributes">
		<xsl:attribute name="onload">
			<xsl:text>init();</xsl:text>
		</xsl:attribute>
	</xsl:template>
	
	
		<xsl:template name="generate-index">
		<xsl:param name="scope" select="(ancestor::book|/)[last()]"/>
	
		<xsl:variable name="terms"
									select="//indexterm[count(.|key('letter',
																									translate(substring(&primary;, 1, 1),
																														&lowercase;,
																														&uppercase;))[&scope;][1]) = 1
																			and not(@class = 'endofrange')]"/>
	
		<xsl:variable name="alphabetical"
									select="$terms[contains(concat(&lowercase;, &uppercase;),
																					substring(&primary;, 1, 1))]"/>
	
		<xsl:variable name="others" select="$terms[not(contains(concat(&lowercase;,
																									 &uppercase;),
																							 substring(&primary;, 1, 1)))]"/>
																							 
    <xsl:call-template name="generate-index-javascript" />
		<div class="index">
			<xsl:if test="$others">
				<div class="indexdiv">
					<h3>
						<xsl:call-template name="gentext">
							<xsl:with-param name="key" select="'index symbols'"/>
						</xsl:call-template>
					</h3>
					<dl>
						<xsl:apply-templates select="$others[count(.|key('primary',
																				 &primary;)[&scope;][1]) = 1]"
																 mode="index-symbol-div">
							<xsl:with-param name="scope" select="$scope"/>
							<xsl:sort select="translate(&primary;, &lowercase;, &uppercase;)"/>
						</xsl:apply-templates>
					</dl>
				</div>
			</xsl:if>
	
			<xsl:apply-templates select="$alphabetical[count(.|key('letter',
																	 translate(substring(&primary;, 1, 1),
																						 &lowercase;,&uppercase;))[&scope;][1]) = 1]"
													 mode="index-div">
				<xsl:with-param name="scope" select="$scope"/>
				<xsl:sort select="translate(&primary;, &lowercase;, &uppercase;)"/>
			</xsl:apply-templates>
		</div>
	</xsl:template>
	
	<xsl:template name="index-searchbox">
		<div id="indexsearchbox">
			<form onsubmit="go()" id="indexseachform">
				<input type="text" id="searchterm" onkeyup="showmatches()" onfocus="init()"/>
				<div id="resultate">
				</div>
			</form>
		</div>
	</xsl:template>
	
	<xsl:template name="generate-index-javascript">
		<xsl:variable name="filename">
			<xsl:call-template name="make-relative-filename">
				<xsl:with-param name="base.dir" select="$base.dir"/>
				<xsl:with-param name="base.name" select="'index.js'"/>
			</xsl:call-template>
		</xsl:variable>
	
		<xsl:call-template name="write.chunk">
			<xsl:with-param name="filename" select="$filename"/>
			<xsl:with-param name="content">
				<xsl:call-template name="index-javascript-code" />
			</xsl:with-param>
			<xsl:with-param name="method" select="'text'"/>
			<xsl:with-param name="quiet" select="$chunk.quietly"/>
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template name="index-javascript-code">
		<xsl:text>targets = [</xsl:text>
		<xsl:for-each select="//indexterm">
			<xsl:sort select="primary|secondary|tertiary"/>
			<xsl:apply-templates select="." mode="js-target" />
			<xsl:if test="not(position()=last())">
				<xsl:text>,</xsl:text>
			</xsl:if>
		</xsl:for-each>
		<xsl:text>];
		
		</xsl:text>
		
		<xsl:text>contents = [</xsl:text>
		<xsl:for-each select="//indexterm">
			<xsl:sort select="primary|secondary|tertiary"/>
			<xsl:apply-templates select="." mode="js-content" />
			<xsl:if test="not(position()=last())">
				<xsl:text>,</xsl:text>
			</xsl:if>
		</xsl:for-each>
		<xsl:text>];
		
		<![CDATA[
var topHit = "";

function showmatches() {
	textbox = document.getElementById("searchterm");
	searchterm = textbox.value.toLowerCase();
	
	
	found = 0;
	for(i=0;i<targets.length;i++) {
		div = document.getElementById("target"+i);
		if ((found<7)&&(searchterm.length!=0)&&(contents[i].toLowerCase().indexOf(searchterm)!=-1)) {
			if (found==0) {
				topHit = targets[i];
				div.firstChild.setAttribute("class","selected");
			} else {
				div.firstChild.setAttribute("class","result");
			}
			div.style.display = "block";
			found++;
		} else {
			div.style.display = "none";
		}
	}
}

function go() {
	window.location.href=topHit;
	return false;
}

//-----------------------------------------------------------

function init() {
	results = document.getElementById("resultate");
	for (i=0;i<targets.length;i++) {
		div = document.createElement("div");
		div.setAttribute("id","target"+i);
		div.setAttribute("class","result");
		a = document.createElement("a");
		a.setAttribute("href",targets[i]);
		a.setAttribute("class","result");
		a.appendChild(document.createTextNode(contents[i]));
		div.appendChild(a);
		
		results.appendChild(div);
	}
	showmatches();
}
			
		]]>
		</xsl:text>	
	</xsl:template>
	
	<xsl:template match="indexterm" mode="js-content">
		<xsl:text>"</xsl:text>
			<xsl:apply-templates select="primary|secondary|tertiary" mode="js-content"/>
		<xsl:text>"</xsl:text>
	</xsl:template>
	
	<xsl:template match="primary" mode="js-content">
		<xsl:value-of select="normalize-space(.)"/>
	</xsl:template>
	
	<xsl:template match="secondary|tertiary" mode="js-content">
		<xsl:text>, </xsl:text><xsl:value-of select="normalize-space(.)"/>
	</xsl:template>
	
	<xsl:template match="indexterm" mode="js-target">

		<!-- sprungziel -->
		<xsl:text>"</xsl:text>
		<xsl:call-template name="href.target">
			<xsl:with-param name="object" select="(ancestor-or-self::set
                     |ancestor-or-self::book
                     |ancestor-or-self::part
                     |ancestor-or-self::reference
                     |ancestor-or-self::partintro
                     |ancestor-or-self::chapter
                     |ancestor-or-self::appendix
                     |ancestor-or-self::preface
                     |ancestor-or-self::article
                     |ancestor-or-self::section
                     |ancestor-or-self::sect1
                     |ancestor-or-self::sect2
                     |ancestor-or-self::sect3
                     |ancestor-or-self::sect4
                     |ancestor-or-self::sect5
                     |ancestor-or-self::refentry
                     |ancestor-or-self::refsect1
                     |ancestor-or-self::refsect2
                     |ancestor-or-self::refsect3
                     |ancestor-or-self::simplesect
                     |ancestor-or-self::bibliography
                     |ancestor-or-self::glossary
                     |ancestor-or-self::index
                     |ancestor-or-self::webpage)[last()]"/>
		</xsl:call-template>
		<xsl:text>"</xsl:text>
</xsl:template>


</xsl:stylesheet>
