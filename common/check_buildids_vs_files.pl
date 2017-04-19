#!/usr/bin/perl

$quiet = 1;
$quiet = 0 if (defined $ENV{TESTLOG_VERBOSITY} && $ENV{TESTLOG_VERBOSITY} ge 2);

$passed = 1;

sub get_filecmd_output
{
	my ($filepath) = @_;
	if ($filepath =~ /ko.xz$/)
	{
		# xzipped module
		$tmpfile = `mktemp`;
		`xzcat $filepath > $tmpfile`;
		$_ = `file $tmpfile 2>/dev/null`;
		unlink $tmpfile;
	}
	elsif ($filepath =~ /ko.bz2$/)
	{
		# bzipped module
		$tmpfile = `mktemp`;
		`bzzcat $filepath > $tmpfile`;
		$_ = `file $tmpfile 2>/dev/null`;
		unlink $tmpfile;
	}
	elsif ($filepath =~ /ko.gz$/)
	{
		# gzipped module
		$tmpfile = `mktemp`;
		`zcat $filepath > $tmpfile`;
		$_ = `file $tmpfile 2>/dev/null`;
		unlink $tmpfile;
	}
	else
	{
		# all other files
		$_ = `file $filepath 2>/dev/null`;
	}

	return $_;
}

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
		$filecmd_output = &get_filecmd_output($filepath);
		($buildid_from_file) = $filecmd_output =~ /BuildID\[sha1\]=(\w{40})/;
	}

	if ($buildid_from_file ne $buildid_from_list)
	{
		$passed = 0;
		print "$filepath has $buildid_from_file buildid but perf shows $buildid_from_list\n" unless $quiet;
	}
}

exit !($passed);
