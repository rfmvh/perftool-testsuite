#!/usr/bin/perl

$quiet = 1;
$quiet = 0 if (defined $ENV{TESTLOG_VERBOSITY} && $ENV{TESTLOG_VERBOSITY} ge 2);

$verbose = 0;
$verbose = 1 if (defined $ENV{TESTLOG_VERBOSITY} && $ENV{TESTLOG_VERBOSITY} ge 3);

$passed = 1;

$koef = 0.003;
$koef = 0.03 if (defined $ENV{PERFTOOL_TESTSUITE_RUNMODE} && defined $ENV{RUNMODE_BASIC} && $ENV{PERFTOOL_TESTSUITE_RUNMODE} eq $ENV{RUNMODE_BASIC});

$k = -1;
$u = -1;
$ku = -1;

while (<STDIN>)
{
	s/\n//;

	$k = int($1) if (/(\d+);;?(?:\w+\/)?[\w\-]+:k\/?;/);
	$u = int($1) if (/(\d+);;?(?:\w+\/)?[\w\-]+:u\/?;/);
	$ku = int($1) if (/(\d+);;?(?:\w+\/)?[\w\-]+(?::ku)?\/?;/);
}

$passed = 0 if (($k == -1) || ($u == -1) || ($ku == -1));

if ($ku != 0)
{
	$diff = ($k + $u - $ku) / $ku;
	$diff *= -1 if $diff < 0;
	if ($diff > $koef)
	{
		print "FAIL ($k + $u - $ku) / $ku = $diff ; it should be $diff < $koef\n" unless $quiet;
		$passed = 0;
	}
	else
	{
		print "PASS ($k + $u - $ku) / $ku = $diff\n" if $verbose;
	}
}
else
{
	if ($k + $u > 0)
	{
		print "FAIL ($k + $u) > 0 while $ku = 0\n" unless $quiet;
		$passed = 0;
	}
}

exit ($passed == 0);
