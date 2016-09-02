#
# FILE DISCONTINUED HERE
# UPDATED VERSION AT
#         https://gitlab.com/yeupou/stalag13/raw/master/usr/share/mediawiki/JSpoiler.php
#
#                                 |     |
#                                 \_V_//
#                                 \/=|=\/
#                                  [=v=]
#                                __\___/_____
#                               /..[  _____  ]
#                              /_  [ [  M /] ]
#                             /../.[ [ M /@] ]
#                            <-->[_[ [M /@/] ]
#                           /../ [.[ [ /@/ ] ]
#      _________________]\ /__/  [_[ [/@/ C] ]
#     <_________________>>0---]  [=\ \@/ C / /
#        ___      ___   ]/000o   /__\ \ C / /
#           \    /              /....\ \_/ /
#        ....\||/....           [___/=\___/
#       .    .  .    .          [...] [...]
#      .      ..      .         [___/ \___]
#      .    0 .. 0    .         <---> <--->
#   /\/\.    .  .    ./\/\      [..]   [..]
#
<?php
/**
 * MediaWiki spoiler extension
 * <spoiler> some text </spoiler>
 * <spoiler text="something"> some text </spoiler>
 * the function registered by the extension hides the text between the
 * tags behind a JavaScript spoiler block.
 *
 * Based on the work of Brian Enigma: http://vanishingpointwiki.com/wiki/MediaWiki:Spoiler
 *
 * (C) Copyright 2009, ddsx <ddsx@live.it>
 * This work is licensed under a Creative Commons Attribution-Noncommercial-Share 
 * Alike 2.5 License.  Some rights reserved.
 * http://creativecommons.org/licenses/by-nc-sa/2.5/
 */
 
// Configuration:
$defaultText = "Contenu caché";
$spoilerCSS = "border: 1px dashed #000000; background-color: #EEEEF2; padding: 3px;";
$spoilerHeaderCSS = "font-size:135%; color:#ff0000;";
$spoilerLinkCSS = "background-color:#EEEEF2; color:#0000FF; padding:2px 4px 2px 4px; border:solid black 1px; text-decoration: underline;";
// End Configuration
 
$wgExtensionFunctions[] = "wfSpoilerExtension";
$wgHooks['OutputPageBeforeHTML'][] = 'spoilerParserHook' ;
$JSpoilerVersion = '1.1';
$wgExtensionCredits['parserhook'][] = array(
					    'name'=>'JSpoiler',
					    'version'=>$JSpoilerVersion,
					    'author'=>'ddsx',
					    'url'=>'http://www.mediawiki.org/wiki/Extension:JSpoiler',
					    'description' => htmlentities('Adds a <spoiler [text="string"]> tag')
					    );
 
function wfSpoilerExtension() {
  global $wgParser;
  // register the extension with the WikiText parser
  $wgParser->setHook( "spoiler", "renderSpoiler" );
}
 
function wfSpoilerJavaScript() {
  global $spoilerCSS;
  global $spoilerHeaderCSS;
  global $spoilerLinkCSS;
        return  "<script language=\"JavaScript\">\n" .
                "\n" . 
                "function getStyleObject(objectId) {\n" .
                "    // checkW3C DOM, then MSIE 4, then NN 4.\n" .
                "    //\n" .
                "    if(document.getElementById) {\n" .
                "      if (document.getElementById(objectId)) {\n" .
                "            return document.getElementById(objectId).style;\n" .
                "      }\n" . 
                "    } else if (document.all) {\n" .
                "      if (document.all(objectId)) {\n" .
                "            return document.all(objectId).style;\n" .
                "      }\n" . 
                "    } else if (document.layers) { \n" . 
                "      if (document.layers[objectId]) { \n" .
                "            return document.layers[objectId];\n" .
                "      }\n" . 
                "    } else {\n" .
                "          return false;\n" .
                "    }\n" .
                "}\n" .
                "\n" .
                "function toggleObjectVisibility(objectId) {\n" .
                "    // first get the object's stylesheet\n" .
                "    var styleObject = getStyleObject(objectId);\n" .
                "\n" .
                "    // then if we find a stylesheet, set its visibility\n" .
                "    // as requested\n" .
                "    //\n" .
                "    if (styleObject) {\n" .
                "        if (styleObject.display == 'none') {\n" .
                "            styleObject.display = 'block';\n" .
                "        } else {\n" .
                "            styleObject.display = 'none';\n" .
                "        }\n" .
                "        return true;\n" .
                "    } else {\n" .
                "        return false;\n" .
                "    }\n" .
                "}\n" .
                "</script>\n" .
                "<style type=\"text/css\"><!--\n" .
                "div.spoiler {" . $spoilerCSS . "}\n" .
                "span.spoilerHeader {" . $spoilerHeaderCSS . "}\n" . 
                "a.spoilerLink {" . $spoilerLinkCSS . "}\n" . 
	  "--></style>\n";
}
 
function spoilerParserHook( &$parser , &$text ) { 
  $text = wfSpoilerJavaScript() . $text;
  return true;
}
 
function wfMakeSpoilerId() {
  $result = "";
  for ( $i=0; $i<20; $i++ ) {
    $result .= chr(rand(ord('A'), ord('Z')));
  }
  return $result;
}
 
// The callback function for converting the input text to HTML output
function renderSpoiler( $input, $argv, $parser ) {
  global $defaultText;                                                                                                                             
  $outputObj = $parser->recursiveTagParse( $input, $frame );                                                                                       
  $spoilerId = wfMakeSpoilerId();                                                                                                                  
  $output  = "<a href=\"#\"onclick=\"toggleObjectVisibility('" . $spoilerId . "'); return false;\" class=\"spoilerLink\">";                        
  if ( !array_key_exists("text", $argv) || $argv["text"] == "" ) {                                                                                 
    $output .= $defaultText . " - ".count(preg_split("/\n/", $input))." ligne(s)</a>\n";                                                                                                      
  } else {                                                                                                                                         
    $output .= $argv["text"] . "</a>\n";                                                                                                     
  }                                                                                                                                                
  $output .= "<div id=\"" . $spoilerId . "\" class=\"spoiler\" style=\"display: none;\">\n";                                                       
  $output .= $outputObj . "\n";                                                                                                                    
  $output .= "</div>\n";                                                                                                                           
  return $output;                                                                                                                                  
}
