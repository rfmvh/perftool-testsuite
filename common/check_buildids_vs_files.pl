#!/usr/bin/perl

$quiet = 0;
$quiet = 1 if (defined $ENV{TESTMODE_QUIET} && $ENV{TESTMODE_QUIET} eq "y");

$passed = 1;

while (<STDIN>)
{
	chomp;
	($buildid_from_list, $filepath) = $_ =~ /^(\w{40})\s+((?:\/[\w\+.-]+)+|(?:\[kernel\.kallsyms\]))$/;
	if ($filepath =~ /\[kernel\.kallsyms\]/)
	{
		$CMD_PERF = $ENV{'CMD_PERF'};
		$buildid_from_file = `$CMD_PERF buildid-list -k`;
		chomp $buildid_from_file;
	}
	else
	{
		$filecmd_output = `file $filepath`;
		($buildid_from_file) = $filecmd_output =~ /BuildID\[sha1\]=(\w{40})/;
	}

	if ($buildid_from_file ne $buildid_from_list)
	{
		$passed = 0;
		print "$filepath has $buildid_from_file buildid but perf shows $buildid_from_list\n" unless $quiet;
	}
}

exit !($passed);
