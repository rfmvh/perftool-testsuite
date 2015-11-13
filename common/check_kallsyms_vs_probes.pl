#!/usr/bin/perl

$matched = 0;
$missing = 0;
$all = 0;

$threshold = 85;

$kallsyms_file = $ARGV[0];
$kfuncs_file = $ARGV[1];

# load the kallsyms into a hash
%kallsyms_hash = ();
open (INFILE, $kallsyms_file) or die "ERROR: Unable to open $kallsyms_file.\n";
@kallsyms_lines = <INFILE>;
close INFILE or die "ERROR: Unable to close $kallsyms_file\n";

for (@kallsyms_lines)
{
	chomp;
	next unless /[\da-fA-F]+\s\w\s(\w+)/;

	$kallsyms_hash{$1} = 1;
}

# check the kfuncs
open (INFILE, $kfuncs_file) or die "ERROR: Unable to open $kfuncs_file\n";
@kfuncs_lines = <INFILE>;
close INFILE or die "ERROR: Unable to close $kfuncs_file\n";

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
printf("%d%% matches\n", $rate);

exit !($rate > $threshold);
