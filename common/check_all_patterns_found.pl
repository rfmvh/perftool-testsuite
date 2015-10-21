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
			$found{$r} = 1;	# FIXME: maybe add counters -- how many times was the regexp matched
		}
	}
}

for $r (@regexps)
{
	unless (exists $found{$r})
	{
		print "Regexp not found: \"$r\"\n";
		$passed = 0;
	}
}

exit ($passed == 0);
