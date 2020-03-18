#!/usr/bin/perl

$num = shift;
$str = "";

while (<>)
{
	chomp;
	$str .= $_ . " ";
}

while ($num--)
{
	@all = split ' ', $str;
	$word = $all[rand @all];
	$str =~ s/$word//;
	print "$word ";
}

print "\n";
