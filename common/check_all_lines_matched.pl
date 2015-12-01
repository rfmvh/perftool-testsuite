#!/usr/bin/perl

@regexps = @ARGV;

$quiet = 0;
$quiet = 1 if (defined $ENV{TESTMODE_QUIET} && $ENV{TESTMODE_QUIET} eq "y");

$passed = 1;

while (<STDIN>)
{
	s/\n//;

	$line_matched = 0;
	for $r (@regexps)
	{
		if (/$r/)
		{
			$line_matched = 1;
			last;
		}
	}

	unless ($line_matched)
	{
		print "Line did not match any pattern: \"$_\"\n" unless $quiet;
		$passed = 0;
	}
}

exit ($passed == 0);
