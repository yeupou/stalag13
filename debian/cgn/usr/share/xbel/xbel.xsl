<?xml version="1.0"?>

<!-- ********************************************************************
     $Id: xbel.xsl,v 1.2 2006-03-23 20:29:51 moa Exp $
     ********************************************************************

     This file is part of the XSL DocBook Stylesheet distribution.
     See ../README or http://nwalsh.com/docbook/xsl/ for copyright
     and other information.

     ******************************************************************** -->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dc="http://purl.org/dc/elements/1.1/">
<xsl:output method="html" encoding="utf-8" omit-xml-declaration="yes" indent="yes" doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN" doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"/>

<!-- ==================================================================== -->

<xsl:template match="xbel">
<html xml:lang="fr">
<head>
<title>Favoris - <xsl:value-of select="title"/></title>
<link href="/attique.css" type="text/css" rel="stylesheet"/>
</head>
<body>
  <ul>
    <xsl:apply-templates/>
  </ul>
</body>
</html>
</xsl:template>

<xsl:template match="info">
</xsl:template>

<xsl:template match="folder">
  <li>
    <xsl:apply-templates select="title"/>
    <ul>
      <xsl:apply-templates select="folder|bookmark"/>
    </ul>
  </li>
</xsl:template>

<xsl:template match="folder/title">
    <b><xsl:apply-templates/></b>
</xsl:template>

<xsl:template match="bookmark">
  <li>
    <a href="{@href}" target="_top">
      <xsl:apply-templates select="title"/>
    </a>
  </li>
</xsl:template>

<xsl:template match="bookmark/title">
    <xsl:apply-templates/>
</xsl:template>

<!-- ==================================================================== -->

<xsl:template match="xbel" mode="dynamic">
  <ul>
    <xsl:apply-templates mode="dynamic"/>
  </ul>
</xsl:template>

<xsl:template match="info" mode="dynamic">
</xsl:template>

<xsl:template match="folder" mode="dynamic">
  <li>
    <xsl:apply-templates select="title" mode="dynamic"/>
    <ul style="display:none" id="{@id}">
      <xsl:apply-templates select="folder|bookmark" mode="dynamic"/>
    </ul>
  </li>
</xsl:template>

<xsl:template match="folder/title" mode="dynamic">
  <b>
    <span>
      <xsl:choose>
	<xsl:when test="../@id">
	  <xsl:attribute name="onClick">
	    <xsl:text>toggleList('</xsl:text>
	    <xsl:value-of select="../@id"/>
	    <xsl:text>')</xsl:text>
	  </xsl:attribute>
	  <xsl:attribute name="class">exlist</xsl:attribute>
	  <xsl:attribute name="style">color: blue</xsl:attribute>
	  <xsl:apply-templates mode="dynamic"/>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:apply-templates mode="dynamic"/>
	</xsl:otherwise>
      </xsl:choose>
    </span>
  </b>
</xsl:template>

<xsl:template match="bookmark" mode="dynamic">
  <li>
    <a href="{@href}" target="_top">
      <xsl:apply-templates select="title" mode="dynamic"/>
    </a>
  </li>
</xsl:template>

<xsl:template match="bookmark/title" mode="dynamic">
    <xsl:apply-templates mode="dynamic"/>
</xsl:template>

<!-- ==================================================================== -->

</xsl:stylesheet>
