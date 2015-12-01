#!/usr/bin/perl

@regexps = @ARGV;

$quiet = 0;
$quiet = 1 if (defined $ENV{TESTMODE_QUIET} && $ENV{TESTMODE_QUIET} eq "y");

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
	print "Pattern not found in the proper order: $r\n" unless $quiet;
	exit 1;
}

exit 0;
