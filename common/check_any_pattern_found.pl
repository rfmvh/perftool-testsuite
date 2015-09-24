#!/usr/bin/perl

@regexps = @ARGV;

while (<STDIN>)
{
	s/\n//;
	for $r (@regexps)
	{
		exit 0 if (/$r/);
	}	
}

exit 1;
