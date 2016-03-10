#!/usr/bin/perl

@regexps = @ARGV;

$quiet = 1;
$quiet = 0 if (defined $ENV{TESTLOG_VERBOSITY} && $ENV{TESTLOG_VERBOSITY} ge 2);

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
