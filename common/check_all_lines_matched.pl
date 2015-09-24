#!/usr/bin/perl

@regexps = @ARGV;

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
		print "Line did not match any pattern: \"$_\"\n";
		$passed = 0;
	}
}

exit ($passed == 0);
