#!/usr/bin/perl

$matched = 0;
$missing = 0;
$all = 0;

$threshold = 85;

$kallsyms_file = $ARGV[0];
$kfuncs_file = $ARGV[1];

$quiet = 1;
$quiet = 0 if (defined $ENV{TESTLOG_VERBOSITY} && $ENV{TESTLOG_VERBOSITY} ge 2);

sub my_die
{
	my $msg = shift;
	unless ($quiet)
	{
		print STDERR "$msg";
	}
	exit 1;
}

# load the kallsyms into a hash
%kallsyms_hash = ();
open (INFILE, $kallsyms_file) or my_die "ERROR: Unable to open $kallsyms_file.\n";
@kallsyms_lines = <INFILE>;
close INFILE or my_die "ERROR: Unable to close $kallsyms_file\n";

for (@kallsyms_lines)
{
	chomp;
	next unless /[\da-fA-F]+\s\w\s(\w+)/;

	$kallsyms_hash{$1} = 1;
}

# check the kfuncs
open (INFILE, $kfuncs_file) or my_die "ERROR: Unable to open $kfuncs_file\n";
@kfuncs_lines = <INFILE>;
close INFILE or my_die "ERROR: Unable to close $kfuncs_file\n";

for (@kfuncs_lines)
{
	chomp;
	if (exists $kallsyms_hash{$_})
	{
		$matched++;
	}
	else
	{
		$missing++;
	}
	$all++;
}

$rate = ($matched / $all) * 100;
printf("%d%% matches\n", $rate) unless $quiet;

exit !($rate > $threshold);
