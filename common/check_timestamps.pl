#!/usr/bin/perl

@regexps = @ARGV;

$quiet = 1;
$quiet = 0 if (defined $ENV{TESTLOG_VERBOSITY} && $ENV{TESTLOG_VERBOSITY} ge 2);

$passed = 1;
$r = 0.0;
$P = 0.0;

$timestamp = @regexps[0];

while (<STDIN>)
{
	s/\n//;

	if (/$timestamp/)
	{
		($p) = $_ =~ /$timestamp/;
		$p *= 1.0;

		unless ($p >= $r)
		{
			print "Invalid timestamp: $p is lower than $r (previous one)\n" unless $quiet;
			exit 1;
		}
		$r = $p;
	}
}


exit 0;
