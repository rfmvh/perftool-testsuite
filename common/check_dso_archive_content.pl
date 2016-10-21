#!/usr/bin/perl

$matched = 0;
$missing = 0;
$all = 0;

$dso_archived_file = $ARGV[0];
$dso_hit_file = $ARGV[1];

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

# load the archived dso names into hashes
%dso_archived_hash_np = ();
%dso_archived_hash_pe = ();
open (INFILE, $dso_archived_file) or my_die "ERROR: Unable to open $dso_archived_file.\n";
@dso_archived_lines = <INFILE>;
close INFILE or my_die "ERROR: Unable to close $dso_archived_file\n";

for (@dso_archived_lines)
{
	chomp;
	/\/([^\/]+)$/;
	$dso_archived_hash_np{$1} = $_;
	$dso_archived_hash_pe{$_} = 1;
}

# check the hit
open (INFILE, $dso_hit_file) or my_die "ERROR: Unable to open $dso_hit_file\n";
@dso_hit_lines = <INFILE>;
close INFILE or my_die "ERROR: Unable to close $dso_hit_file\n";

for (@dso_hit_lines)
{
	chomp;
	if (exists $dso_archived_hash_pe{$_})
		{ $matched++; }
	else
	{
		/\/([^\/]+)$/;
		if (exists $dso_archived_hash_np{$1})
		{
			$diff = `diff --brief $_ $dso_archived_hash_np{$1}`;
			if ($diff =~ /Files.*differ/)
			{
				$missing++;
				printf("%s hit but missing in archive\n", $_) unless $quiet;
			}
			else
				{ $matched++; }
		}
		else
		{
			$missing++;
			printf("%s hit but missing in archive\n", $_) unless $quiet;
		}
	}
	$all++;
}

exit !(($matched == $all) && ($missing == 0));
