#!/usr/bin/perl

$quiet = 1;
$quiet = 0 if (defined $ENV{TESTLOG_VERBOSITY} && $ENV{TESTLOG_VERBOSITY} ge 2);

$passed = 1;

while (<STDIN>)
{
	chomp;
	($buildid_from_list, $filepath) = $_ =~ /^(\w{40})\s+((?:\/[\w\+.-]+)+|(?:\[[\w\.]+\]))$/;
	if ($filepath =~ /\[[\w\.]+\]/)
	{
		next unless ($filepath =~ /\[kernel\.kallsyms\]/);
		$CMD_PERF = $ENV{'CMD_PERF'};
		$buildid_from_file = `$CMD_PERF buildid-list -k`;
		chomp $buildid_from_file;
	}
	else
	{
		$filecmd_output = `file $filepath 2>/dev/null`;
		($buildid_from_file) = $filecmd_output =~ /BuildID\[sha1\]=(\w{40})/;
	}

	if ($buildid_from_file ne $buildid_from_list)
	{
		$passed = 0;
		print "$filepath has $buildid_from_file buildid but perf shows $buildid_from_list\n" unless $quiet;
	}
}

exit !($passed);
