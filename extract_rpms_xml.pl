#!/usr/bin/perl
use strict;
use XML::Parser;

# This program uses the XML::Parser module of Perl to extract the names of the packages from the given repository.
my $filename = shift ;

open(XMLFILE,$filename);
my $tag;
my $parser;
$parser = new XML::Parser(ErrorContext => 2);
$parser->setHandlers(Start => \&start_handler, Char => \&char_handler, End => \&end_handler);
$parser->parsefile($filename);


sub start_handler()
{
  my $parse = shift;
     $tag = shift;
}

sub char_handler()
{
	
  my ($parse,$data)= @_;
	if($tag eq "name") { print "$data";}
} 

sub end_handler()
{
  my ($parse,$tag)= @_;
	if($tag eq "name"){ print "\n";}
}
