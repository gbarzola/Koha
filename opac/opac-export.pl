#!/usr/bin/perl

# Parts Copyright Catalyst IT 2011
#
# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# Koha is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Koha; if not, see <http://www.gnu.org/licenses>.

use Modern::Perl;

use C4::Record;
use C4::Auth;
use C4::Output;
use C4::Biblio;
use CGI qw ( -utf8 );
use C4::Auth;
use C4::Ris;

my $query = new CGI;
my $op=$query->param("op")||''; #op=export is currently the only use
my $format=$query->param("format")||'utf8';
my $biblionumber = $query->param("bib")||0;
$biblionumber = int($biblionumber);
my ($marc, $error)= ('','');

$marc = GetMarcBiblio($biblionumber, 1) if $biblionumber;
if(!$marc) {
    print $query->redirect("/cgi-bin/koha/errors/404.pl");
    exit;
}
elsif ($format =~ /endnote/) {
    $marc = marc2endnote($marc);
    $format = 'endnote';
}
elsif ($format =~ /marcxml/) {
    $marc = marc2marcxml($marc);
    $format = 'marcxml';
}
elsif ($format=~ /mods/) {
    $marc = marc2modsxml($marc);
    $format = 'mods';
}
elsif ($format =~ /ris/) {
    $marc = marc2ris($marc);
    $format = 'ris';
}
elsif ($format =~ /bibtex/) {
    $marc = marc2bibtex(C4::Biblio::GetMarcBiblio($biblionumber),$biblionumber);
    $format = 'bibtex';
}
elsif ($format =~ /dc$/) {
    $marc = marc2dcxml(undef, undef, $biblionumber, $format);
    $format = "dublin-core.xml";
}
elsif ($format =~ /marc8/) {
    ($error,$marc) = changeEncoding($marc,"MARC","MARC21","MARC-8");
    $marc = $marc->as_usmarc() unless $error;
    $format = 'marc8';
}
elsif ($format =~ /utf8/) {
    C4::Charset::SetUTF8Flag($marc,1);
    $marc = $marc->as_usmarc();
    $format = 'utf8';
}
elsif ($format =~ /marcstd/) {
    C4::Charset::SetUTF8Flag($marc,1);
    ($error,$marc) = marc2marc($marc, 'marcstd', C4::Context->preference('marcflavour'));
    $format = 'marcstd';
}
elsif ( $format =~ /isbd/ ) {
    $marc   = GetISBDView($biblionumber, "opac");
    $format = 'isbd';
}
else {
    $error= "Format $format is not supported.";
}

if ($error){
    print $query->header();
    print $query->start_html();
    print "<h1>An error occurred </h1>";
    print $query->escapeHTML("$error");
    print $query->end_html();
}
else {
    if ($format eq 'marc8'){
        print $query->header(
            -type => 'application/marc',
            -charset=>'ISO-2022',
            -attachment=>"bib-$biblionumber.$format");
    }
    elsif ( $format eq 'isbd' ) {
        print $query->header(
            -type       => 'text/plain',
            -charset    => 'utf-8',
            -attachment =>  "bib-$biblionumber.txt"
        );
    } else {
        binmode STDOUT, ':encoding(UTF-8)';
        print $query->header(
            -type => 'application/octet-stream',
            -charset => 'utf-8',
            -attachment => "bib-$biblionumber.$format"
        );
    }
    print $marc;
}

1;
