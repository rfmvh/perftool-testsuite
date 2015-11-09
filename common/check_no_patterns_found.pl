#!/usr/bin/perl

@regexps = @ARGV;

%found = ();
$passed = 1;

while (<STDIN>)
{
	s/\n//;

	for $r (@regexps)
	{
		if (/$r/)
		{
			$found{$r} = 1;
		}
	}
}

for $r (@regexps)
{
	if (exists $found{$r})
	{
		print "Regexp found: \"$r\"\n";
		$passed = 0;
	}
}

exit ($passed == 0);
