#!/usr/bin/perl

$passed = 1;

while (<STDIN>)
{
	chomp;
	($buildid_from_list, $filepath) = $_ =~ /^(\w{40})\s+((?:\/[\w\+.-]+)+)$/;
	$filecmd_output = `file $filepath`;
	($buildid_from_file) = $filecmd_output =~ /BuildID\[sha1\]=(\w{40})/;

	if ($buildid_from_file ne $buildid_from_list)
	{
		$passed = 0;
		print "$filepath has $buildid_from_file buildid but perf shows $buildid_from_list\n";
	}
}

exit !($passed);
