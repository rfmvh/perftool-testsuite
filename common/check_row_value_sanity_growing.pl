#!/usr/bin/perl

$regexp = @ARGV[0];

$max_printed_lines = 20;
$max_printed_lines = $ENV{TESTLOG_ERR_MSG_MAX_LINES} if (defined $ENV{TESTLOG_ERR_MSG_MAX_LINES});

$quiet = 1;
$quiet = 0 if (defined $ENV{TESTLOG_VERBOSITY} && $ENV{TESTLOG_VERBOSITY} ge 2);

$passed = 1;
$lines_printed = 0;

while (<STDIN>)
{
	s/\n//;

	if (/$regexp/ and $1 > $2)
	{
		if ($lines_printed++ < $max_printed_lines)
		{
			print "line: \"$_\" does not match $1 <= $2 equation\n" unless $quiet;
		}
		$passed = 0;
	}
}

exit ($passed == 0);
