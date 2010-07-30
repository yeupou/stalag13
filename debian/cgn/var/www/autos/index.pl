#!/usr/bin/perl
#
# Copyright (c) 2006 Mathieu Roy <yeupou--gnu.org>
# http://yeupou.coleumes.org
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
#   USA
#
# $Id: index.pl,v 1.2 2006-06-02 16:34:49 moa Exp $

use strict;
use CGI qw(:standard Link);
use CGI::Carp qw(fatalsToBrowser);
use POSIX qw(strftime);
use File::Find::Rule;
use File::Basename;

# Get previously picked images
my ($previous1, $previous2, $previous3, $previous4, $previous5, $previous6, $previous7, $previous8, $previous9) = (split(",", cookie("autotestlist")));

# Fetch images
my @files = File::Find::Rule->file()
    ->name('*.jpg')
    ->in("/var/www/autos");

# Pick one random
my $thisone;
my $notfound = 1;
while ($notfound){
    $thisone = $files[ rand @files ];
    $thisone = basename($thisone, ".jpg");
    next if $notfound eq $previous1;
    next if $notfound eq $previous2;
    next if $notfound eq $previous3;
    next if $notfound eq $previous4;
    next if $notfound eq $previous5;
    next if $notfound eq $previous6;
    next if $notfound eq $previous7;
    next if $notfound eq $previous8;
    next if $notfound eq $previous9;
    $notfound = 0;
}

print header(-cookie => cookie(-name => "autotestlist", -value => "$thisone,$previous1,$previous2,$previous3,$previous4,$previous5,$previous6,$previous7,$previous8"));

print start_html(-title => "Test de reconnaisance des oitures", 
		 -head => Link({-rel=>'stylesheet', -type=>'text/css', -href=>'index.css'}));
print h1("Test de reconnaissance des oitures");
print p("Marque ? Modele ou type (berline, coupe, cabriolet, break, utilitaire) ?");

print '<a href="."><img src="'.$thisone.'.jpg" alt="???" /></a>';
$thisone =~ s/\..*//g;
print '<h4 id="question" class="question" onclick="document.getElementById(\'question\').style.visibility=\'hidden\'; document.getElementById(\'reponse\').style.visibility=\'visible\'; document.getElementById(\'question\').style.display=\'none\';">(cliquer ici pour la reponse)</h4>';
print '<h4 id="reponse" class="reponse">'.$thisone.'</h4>'; 

print end_html();
