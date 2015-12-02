#!/usr/bin/perl

@regexps = @ARGV;

$max_printed_lines = 20;
$max_printed_lines = $ENV{ERROR_MESSAGE_MAX_LINES} if (defined $ENV{ERROR_MESSAGE_MAX_LINES});

$quiet = 0;
$quiet = 1 if (defined $ENV{TESTMODE_QUIET} && $ENV{TESTMODE_QUIET} eq "y");

$passed = 1;
$lines_printed = 0;

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
		if ($lines_printed++ < $max_printed_lines)
		{
			print "Line did not match any pattern: \"$_\"\n" unless $quiet;
		}
		$passed = 0;
	}
}

exit ($passed == 0);
