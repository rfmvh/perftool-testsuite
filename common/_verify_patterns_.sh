#!/bin/bash

TEST_NAME="common"

. ../common/init.sh
. ../common/patterns.sh

TEST_RESULT=0

while read line; do
	# get a regexp
	if [[ $line =~ ^export ]]; then
		RE=`echo $line | perl -pe 's/^export //;s/=.+$//'`
		continue
	fi

	# example text to be accepted
	# (starts with '#' and 4 spaces)
	echo "$line" | grep -q -P '^#    '
	if [ $? -eq 0 ]; then
		T=`echo "$line" | perl -pe 's/^#\s{4}//'`
		echo "$T" | ./check_all_patterns_found.pl "^${!RE}\$"
		print_results 0 $? "$RE accepts $T"
		(( TEST_RESULT += $? ))
		continue
	fi

	# example text to be refused
	# (starts with '#!' and 3 spaces)
	echo "$line" | grep -q -P '^#!   '
	if [ $? -eq 0 ]; then
		T=`echo "$line" | perl -pe 's/^#!\s{3}//'`
		echo "$T" | ./check_no_patterns_found.pl "^${!RE}\$"
		print_results 0 $? "$RE refuses $T"
		(( TEST_RESULT += $? ))
		continue
	fi
done < patterns.sh

print_overall_results "$TEST_RESULT"
exit $?
