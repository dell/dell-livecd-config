#!/usr/bin/perl
use strict;

my $filename = shift ;

open(XMLFILE,$filename);

my $line;

while(<XMLFILE>)
{
	 $line = $_;
	if($line =~ m/^<package/) 
	{
	   	$line =~ m/<name>([^<]+)<\/name>/;
		
		#print "name == $1 ";
		my  $name = $1;
		
		while (<XMLFILE>)
		{
			$line = $_;
		 	last if $_ =~ m/<location href=/ ;
		}
	 	
		$line	=~ m/<location href="([^"]+)"\/>/;
		#print " location= $1 \n";
	        	
		my $location = $1;
			
		if($location !~ m/\.src\.rpm$/)
		{
			if ($location !~ m/headers/)
			{
				if($location !~ m/-repository/)
				{		
					print "$name\n";
				}
			} 
		}
	}
}

