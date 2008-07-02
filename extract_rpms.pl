#!/usr/bin/perl
#This script extracts all the names of the packages available at the given repoistory. 
#This script uses the meta-data (primary.xml.gz) files in the repository to extract the packages' names.
#
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
		
		my  $name = $1; #name of the package
		
		while (<XMLFILE>)
		{
			$line = $_;
		 	last if $_ =~ m/<location href=/ ;
		}
	 	
		$line	=~ m/<location href="([^"]+)"\/>/; #extract the location to find if the package is a source package or not.
	        	
		my $location = $1;
			
		if($location !~ m/\.src\.rpm$/)    #exclude all the src packages
		{
			if ($location !~ m/headers/) # exclude all the header packages
			{
				if($location !~ m/-repository/)
				{		
					print "$name\n";
				}
			} 
		}
	}
}

