#!/usr/bin/perl

#
# NewsMag2k v0.1 (beta)
#
# Complete rewrite of NewsMag, originally released in 1994
# For more information see README
#
# Copyright 1993-2015 Philipp Giebel <stimpy@kuehlbox.wtf>
# License: BSD
#
# NewsMag WHQ: Kuehlbox BBS
#              http://kuehlbox.ws
#              telnet://kuehlbox.ws
#              fidonet: 2:240/5853
#

use strict;
use warnings;
use utf8;
use Text::Wrap;
use Encode qw(encode decode);
use Getopt::Long;
use Data::Dumper;

my $output;
my $entryhdrfile = 'entryhdr.ans';
my $entryhdr;
my $etmp;
my $fh;
my $ref;
my @newslist;
my @news;
my $sl;
my $dl;
my $cl;
my $sa;
my $da;
my $ca;
my $stmp;
my $dtmp;
my $ctmp;
my $pre;
my $c = 0;
my $copyright = 'Created with NewsMag2k';
my $VER = '0.1';
my $optHdr = 'newshdr.ans';
my $optFtr = 'newsftr.ans';
my $optEntry = 'entryhdr.ans';
my $optInfile = 'news.txt';
my $optOutfile = 'news.ans';
my $optEnc = 'CP437';
my $optPrint;
my $optHelp;
my $optLonghelp;
my $optQuiet;
my $optNum = 0;

sub getPad {
  my $tl;
  my $ta;
  if ( $_[0] =~ /\@$_[1]\@(\d+)(.)\@/g ) {
    $tl = $1;
    $ta = $2;
  } else {
    if ( $_[1] eq 'SUBJECT' ) {
      $tl = 32;
      $ta = "R";
    } elsif ( $_[1] eq 'DATE' ) {
      $tl = 16;
      $ta = "L";
    } elsif ( $_[1] eq 'CONTENT' ) {
      $tl = 75;
      $ta = "R";
    }
  }
  return ( $tl, $ta );
}

sub padIt {
  my $ttmp;
  if ( $_[2] eq "L" ) {
    $ttmp = sprintf( "%".$_[1]."s", $_[0] );
  } else {
    $ttmp = sprintf( "%-".$_[1]."s", $_[0] );
  }
  return $ttmp;
}

sub getTmpl {
  my $ret;
  if ( open(my $fh, "<:encoding($_[1])", $_[0]) ) {
    while (my $row = <$fh>) {
      chomp $row;
      $ret .= $row ."\n";
    }
    close $fh;
    print "OK\n";
  } else {
    $ret = $_[2];
    print "NOT FOUND - using default\n";
  }
  return $ret;
}

GetOptions( 'filehdr=s' => \$optHdr,
            'fileftr=s' => \$optFtr,
            'fileentry=s' => \$optEntry,
            'infile=s' => \$optInfile,
            'outfile=s' => \$optOutfile,
            'encoding=s' => \$optEnc,
            'num=i' => \$optNum,
            'p|print' => \$optPrint,
            'h|help' => \$optHelp,
            'longhelp' => \$optLonghelp,
            'q|quiet' => \$optQuiet );


my $old_fh = select(STDOUT);
$| = 1;
select($old_fh);

if ( !$optQuiet ) {
  print ' _______                         _____
 \      \   ______  _  ________ /     \ _____     ____
 /   |   \_/ __ \ \/ \/ /  ___//  \ /  \\\\__  \   / ___\    by kuehlbox.wtf
/    |    \  ___/\     /\___ \/    Y    \/ __ \_/ /_/  >   2:240/5853
\____|__  /\___  >\/\_//____  >____|__  (____  /\___  /
        \/     \/           \/        \/     \//_____/2k   v'."$VER
_____________________________________________________________________________

";
}

if ( $optHelp || $optLonghelp ) {
  print "NewsMag creates beautiful ansi files out of dull textfiles, so you can easily
provide your BBS users with a stylish news file without having to hassle with
an ansi editor everytime...

Parameters:  --filehdr=newshdr.ans       Header template
             --fileftr=newsftr.ans       Footer template
             --fileentry=entryhdr.ans    Entries template
             --infile=news.txt           Input text-file
             --outfile=news.ans          Output ansi-file
             --encoding=CP437            Output file encoding
             --num=0                     Only display <num> entries (0=all)
             -p | --print                Print output to STDOUT
             -q | --quiet                Be quiet (overrides -p)
             -h | --help                 Print this help
             --longhelp                  Print more detailed help

";
}

if ( $optLonghelp ) {
  print "
Files:       

 - news.txt
   The input-file containing news formated like this:
     <DATE>
     <SUBJECT>
     <CONTENT>
     \@NEXT\@
     <DATE>
     <SUBJECT>
     <CONTENT>
   e.g:
     2015-03-18
     Hooray, I'm using NewsMag!
     From now on and forever more, I'm using the infamous, so absolutely fabolous NewsMag by kuehlbox.wtf
     \@NEXT\@
     2015-03-19
     This is incredible!
     I just can't contain myself:
     NewsMag just made my life complete!

 - newshdr.ans
   Header template. If not found, a default, hardcoded version will be used.

 - entryhdr.ans
   Template for the news entries. If not fount, a default version will be used.
   This file has to contain some variables:
    \@SUBJECT\@  Will be replaced by the <SUBJECT> from your news.txt,
               padded to 32 characters added to the right, by default.
    \@DATE\@     Will be replaced by the <DATE> from your news.txt,
               padded to 16 characters added to the left, by default.
    \@CONTENT\@  Will be replaced by the <CONTENT> from your news.txt, but
               with a little bit of magic:
               Lines will be wrapped at 78 characters, by default and every
               new line will start with the same characters, the first line
               did. See example entryhdr.ans for an example.
 
 - newsftr.ans
   Footer Template. If not found, a default version will be used.
   This file has to contain a variable:
    \@COPYRIGHT\@  Will be replaced by a short copyright-notice. If not found, 
                 the copyright will be appended to the news.ans anyway..
 
 - news.ans
   The output-file to include into your BBS. Doesn't really have to be ansi - 
   combined with the --encoding switch, you can create a whole lot of different
   formats...


Variable padding:

 You can set the padding of a variable by adding <width><side>\@.
   e.g: \@SUBJECT\@32R\@
        This will pad the variable SUBJECT to 32 by adding whitespace 
        to the right.

";
}
if ( $optHelp || $optLonghelp ) {
  exit 1;
}

print " - Parsing input file: " if !$optQuiet;
open($fh, '<:encoding(utf-8)', $optInfile)
  or die "Could not open input-file '$optInfile'\n                       Try '-h' for help\n";

while (my $row = <$fh>) {
  chomp $row;
  if ( $row eq '@NEXT@' ) {
    push( @newslist, [ @news ] );
    undef @news;
  } elsif ( defined $news[1] ) {
    $news[2] .= $row ."\n";
  } elsif ( defined $news[0] ) {
    $news[1] = $row;
  } else {
    $news[0] = $row;
  }
}

push( @newslist, [ @news ] );
undef @news;
@newslist = sort { $b->[0] cmp $a->[0] } @newslist;

print "OK\n" if !$optQuiet;
print " - Reading Templates:\n" if !$optQuiet;
print "   - Header: " if !$optQuiet;
$output .= getTmpl( $optHdr, $optEnc, ' _______
 \      \   ______  _  ________
 /   |   \_/ __ \ \/ \/ /  ___/
/    |    \  ___/\     /\___ \
\____|__  /\___  >\/\_//____  >
_______ \/ ___ \/ _________ \/ ______________________________________________
' );

print "   - Entries: " if !$optQuiet;

$entryhdr .= getTmpl( $optEntry, $optEnc, "\n---[ \@SUBJECT\@32R\@ ]---------------[ \@DATE\@16L\@ ]---\n\@CONTENT\@\n" );

print " - Processing output: " if !$optQuiet;
foreach my $n ( @newslist ) {
  $c++;
  if ( $c > $optNum && $optNum > 0 ) {
    last;
  }  
  $etmp = $entryhdr;
  ( $sl, $sa ) = getPad( "$etmp", 'SUBJECT' );
  ( $dl, $da ) = getPad( "$etmp", 'DATE' );
  ( $cl, $ca ) = getPad( "$etmp", 'CONTENT' );

  if ( $etmp =~ /(.*?)\@CONTENT/g ) {
    $pre = $1;
  } else {
    $pre = '';
  }

  $stmp = padIt( @$n[1], $sl, $sa );
  $dtmp = padIt( @$n[0], $dl, $da );

  $cl += length( $pre );
  $Text::Wrap::columns = $cl;
  $ctmp = wrap( $pre, $pre, @$n[2] );
  chomp( $ctmp );

  $etmp =~ s/\@SUBJECT\@(?:(\d+)(.)\@)?/$stmp/g;
  $etmp =~ s/\@DATE\@(?:(\d+)(.)\@)?/$dtmp/g;
  $etmp =~ s/.*\@CONTENT\@(?:(\d+)(.)\@)?/$ctmp/g;

  $output .= $etmp;
}
print "OK\n" if !$optQuiet;
print " - Appending Footer: " if !$optQuiet;

$output .= getTmpl( $optFtr, $optEnc, "\n---------------------------------[ \@COPYRIGHT\@ ]----\n" );

if ( $output =~ s/\@COPYRIGHT\@/$copyright/g ) {
  print "   - Copyright OK\n" if !$optQuiet;
} else {
  print "   - Copyright tag not found. Appending automatically.\n";
  $output .= "\n$copyright\n" if !$optQuiet;
}

print " - Writing output file: " if !$optQuiet;
open($fh, ">:encoding($optEnc)", $optOutfile) or die "Could not open file '$optOutfile' $!\n";
print $fh $output;
close $fh;
print "OK\n" if !$optQuiet;
print "* FINISHED\n" if !$optQuiet;

if ( $optPrint && !$optQuiet ) {
  print "\n____[ Your output looks something like that: ]_______________________________\n\n";
  print encode('utf-8', $output );
  print "\n";
}
print "\n" if !$optQuiet;
