#!/usr/bin/perl

@regexps = @ARGV;

$passed = 1;
$r = shift @regexps;

while (<STDIN>)
{
	s/\n//;

	if (/$r/)
	{
		$r = shift @regexps;
	}
}

if (defined $r)
{
	print "Pattern not found in the proper order: $r\n";
	exit 1;
}

exit 0;
