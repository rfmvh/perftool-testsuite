#!/bin/bash

#
#	test_optimization_levels.sh of perf_probe test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This testcase tests, whether all the optimization levels
#	work with uprobes.
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0

check_uprobes_available
if [ $? -ne 0 ]; then
	print_overall_skipped
	exit 0
fi

# clean up before we start
clear_all_probes
find . -name perf.data\* | xargs -r rm


### function argument probing with different optimization levels

for prg in $CURRENT_TEST_DIR/examples/test_opts_*; do
	FILENAME=`basename $prg`
	OPT_LEVEL=${FILENAME##test_opts_}

	### function argument probing :: add

	# we want to trace values of the variable (argument) 'a' along with the function calls
	$CMD_PERF probe -x $prg --add 'foo e' > $LOGS_DIR/opt_levels_${OPT_LEVEL}_add.log 2>&1
	PERF_EXIT_CODE=$?

	../common/check_all_patterns_found.pl "probe_test_opt\w*:foo" < $LOGS_DIR/opt_levels_${OPT_LEVEL}_add.log
	CHECK_EXIT_CODE=$?

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "function argument with -O$OPT_LEVEL :: add"
	(( TEST_RESULT += $? ))


	### function argument probing :: use

	# perf record should catch samples including the argument's value
	PROBE_PREFIX=`$CMD_PERF probe -l | perl -ne 'print "$1" if /\s+(\w+):/'`
	$CMD_PERF record -e "$PROBE_PREFIX:"'*' -o $CURRENT_TEST_DIR/perf.data $prg 11 22 33 44 55 > /dev/null 2> $LOGS_DIR/opt_levels_${OPT_LEVEL}_record.log
	PERF_EXIT_CODE=$?

	# perf record should catch exactly 9 samples
	../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "1 sample" < $LOGS_DIR/opt_levels_${OPT_LEVEL}_record.log
	CHECK_EXIT_CODE=$?

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "function argument with -O$OPT_LEVEL :: record"
	(( TEST_RESULT += $? ))

	# perf script should report the function calls with the correct arg values
	$CMD_PERF script -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/opt_levels_${OPT_LEVEL}_script.log
	PERF_EXIT_CODE=$?

	# checking for the perf script output sanity
	REGEX_SCRIPT_LINE="\s*$FILENAME\s+$RE_NUMBER\s+\[$RE_NUMBER\]\s+$RE_NUMBER:\s+probe_test_opts\w*:foo\w*:\s+\($RE_NUMBER_HEX\) e=55"
	../common/check_all_lines_matched.pl "$REGEX_SCRIPT_LINE" < $LOGS_DIR/opt_levels_${OPT_LEVEL}_script.log
	CHECK_EXIT_CODE=$?
	../common/check_all_patterns_found.pl "$REGEX_SCRIPT_LINE" < $LOGS_DIR/opt_levels_${OPT_LEVEL}_script.log
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "function argument with -O$OPT_LEVEL :: script"
	(( TEST_RESULT += $? ))

	clear_all_probes
done


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
