#!/usr/bin/perl
use strict;
use XML::Parser;

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
  #print "\nstart : $tag"	
}

sub char_handler()
{
	
  my ($parse,$data)= @_;
#	print "char $data\t ";
	if($tag eq "name") { print "$data";}
	#$tag = "none";
} 

sub end_handler()
{
  my ($parse,$tag)= @_;
	if($tag eq "name"){ print "\n";}
}
