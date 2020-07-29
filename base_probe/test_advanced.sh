#!/bin/bash

#
#	test_advanced.sh of perf_probe test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This testcase tries some more advanced probes, capturing
#	values of variables, registers etc. The perf-script tool is
#	used for processing the results.
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0


######## function argument uprobing ########

check_uprobes_available
if [ $? -ne 0 ]; then
	print_testcase_skipped "function argument probing"
	print_testcase_skipped "function retval probing"
	print_testcase_skipped "function string argument probing"
else

# clean up before we start
clear_all_probes
find . -name perf.data\* | xargs -r rm


### function argument probing :: add

# we want to trace values of the variable (argument) 'a' along with the function calls
$CMD_PERF probe -x $CURRENT_TEST_DIR/examples/advanced --add 'isprime a' > $LOGS_DIR/advanced_funcargs_add.log 2>&1
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "probe_advanced:isprime" < $LOGS_DIR/advanced_funcargs_add.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "function argument probing :: add"
(( TEST_RESULT += $? ))


### function argument probing :: use

# perf record should catch samples including the argument's value
$CMD_PERF record -e 'probe_advanced:isprime' -o $CURRENT_TEST_DIR/perf.data $CURRENT_TEST_DIR/examples/advanced > /dev/null 2> $LOGS_DIR/advanced_funcargs_record.log
PERF_EXIT_CODE=$?

# perf record should catch exactly 9 samples
../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "9 samples" < $LOGS_DIR/advanced_funcargs_record.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "function argument probing :: record"
(( TEST_RESULT += $? ))

# perf script should report the function calls with the correct arg values
$CMD_PERF script -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/advanced_funcargs_script.log
PERF_EXIT_CODE=$?

# checking for the perf script output sanity
REGEX_SCRIPT_LINE="\s*advanced\s+$RE_NUMBER\s+\[$RE_NUMBER\]\s+$RE_NUMBER:\s+probe_advanced:isprime:\s+\($RE_NUMBER_HEX\) a=$RE_NUMBER"
../common/check_all_lines_matched.pl "$REGEX_SCRIPT_LINE" < $LOGS_DIR/advanced_funcargs_script.log
CHECK_EXIT_CODE=$?

# checking whether the values are really correct
../common/check_exact_pattern_order.pl "a=2" "a=3" "a=4" "a=5" "a=6" "a=7" "a=13" "a=17" "a=19" < $LOGS_DIR/advanced_funcargs_script.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "function argument probing :: script"
(( TEST_RESULT += $? ))


# clean up between the tests
clear_all_probes
find . -name perf.data\* | xargs -r rm


### function retval probing :: add

# we want to trace return values of the function along with the function calls
$CMD_PERF probe -x $CURRENT_TEST_DIR/examples/advanced --add 'incr%return $retval' > $LOGS_DIR/advanced_funcretval_add.log 2>&1
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "probe_advanced:incr" < $LOGS_DIR/advanced_funcretval_add.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "function retval probing :: add"
(( TEST_RESULT += $? ))


### function retval probing :: use

# perf record should catch samples including the function return value
$CMD_PERF record -e 'probe_advanced:incr*' -o $CURRENT_TEST_DIR/perf.data $CURRENT_TEST_DIR/examples/advanced > /dev/null 2> $LOGS_DIR/advanced_funcretval_record.log
PERF_EXIT_CODE=$?

# perf record should catch exactly 9 samples
../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "9 samples" < $LOGS_DIR/advanced_funcretval_record.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "function retval probing :: record"
(( TEST_RESULT += $? ))

# perf script should report the function calls with the correct return values
$CMD_PERF script -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/advanced_funcretval_script.log
PERF_EXIT_CODE=$?

# checking for the perf script output sanity
REGEX_SCRIPT_LINE="\s*advanced\s+$RE_NUMBER\s+\[$RE_NUMBER\]\s+$RE_NUMBER:\s+probe_advanced:incr\w*:\s+\($RE_NUMBER_HEX\s+<\-\s+$RE_NUMBER_HEX\) arg1=0x$RE_NUMBER_HEX"
../common/check_all_lines_matched.pl "$REGEX_SCRIPT_LINE" < $LOGS_DIR/advanced_funcretval_script.log
CHECK_EXIT_CODE=$?

# checking whether the values are really correct
../common/check_exact_pattern_order.pl "arg1=0x0" "arg1=0x2" "arg1=0x4" "arg1=0x6" "arg1=0x8" "arg1=0xa" "arg1=0xc" "arg1=0xe" "arg1=0x10" < $LOGS_DIR/advanced_funcretval_script.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "function retval probing :: script"
(( TEST_RESULT += $? ))


# clean up between the tests
clear_all_probes
find . -name perf.data\* | xargs -r rm


### function string argument probing :: add

# we want to trace values of the variable (argument) 'a' along with the function calls
$CMD_PERF probe -x $CURRENT_TEST_DIR/examples/strings --add 'str_search s:string' > $LOGS_DIR/advanced_funcstrargs_add.log 2>&1
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "probe_strings:str_search" < $LOGS_DIR/advanced_funcstrargs_add.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "function string argument probing :: add"
(( TEST_RESULT += $? ))


### function string argument probing :: use

# perf record should catch samples including the argument's value
$CMD_PERF record -e 'probe_strings:str_search' -o $CURRENT_TEST_DIR/perf.data $CURRENT_TEST_DIR/examples/strings > /dev/null 2> $LOGS_DIR/advanced_funcstrargs_record.log
PERF_EXIT_CODE=$?

# perf record should catch exactly 1 sample
../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "1 sample" < $LOGS_DIR/advanced_funcstrargs_record.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "function string argument probing :: record"
(( TEST_RESULT += $? ))

# perf script should report the function calls with the correct arg values
$CMD_PERF script -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/advanced_funcstrargs_script.log
PERF_EXIT_CODE=$?

# checking for the perf script output sanity
REGEX_SCRIPT_LINE="\s*strings\s+$RE_NUMBER\s+\[$RE_NUMBER\]\s+$RE_NUMBER:\s+probe_strings:str_search:\s+\($RE_NUMBER_HEX\) s_string=\"root\""
../common/check_all_lines_matched.pl "$REGEX_SCRIPT_LINE" < $LOGS_DIR/advanced_funcstrargs_script.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "$REGEX_SCRIPT_LINE" < $LOGS_DIR/advanced_funcstrargs_script.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "function string argument probing :: script"
(( TEST_RESULT += $? ))

fi



######## function argument kprobing ########

check_kprobes_available && test "$MY_ARCH" != "s390x"
if [ $? -ne 0 ]; then
	print_testcase_skipped "function string argument kprobing"
else

# clean up between the tests
clear_all_probes
find . -name perf.data\* | xargs -r rm


### function string argument kprobing :: add

# do_sys_open argument 'filename' needs to be treated as a string
$CMD_PERF probe -a 'do_sys_open filename:string' > $LOGS_DIR/advanced_k_funcstrargs_add.log 2>&1
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "probe:do_sys_open" < $LOGS_DIR/advanced_k_funcstrargs_add.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "function string argument kprobing :: add"
(( TEST_RESULT += $? ))


### function string argument kprobing :: use

# perf record should catch samples including the argument's value even if it is a string
FILE_TO_BE_OPEN="/proc/cmdline"
$CMD_PERF record -e 'probe:do_sys_open*' -o $CURRENT_TEST_DIR/perf.data -- cat $FILE_TO_BE_OPEN > /dev/null 2> $LOGS_DIR/advanced_k_funcstrargs_record.log
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" < $LOGS_DIR/advanced_k_funcstrargs_record.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "function string argument kprobing :: record"
(( TEST_RESULT += $? ))

# perf script should report the function calls with the correct arg values
$CMD_PERF script -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/advanced_k_funcstrargs_script.log 2> $LOGS_DIR/advanced_k_funcstrargs_script.err
PERF_EXIT_CODE=$?

test $TESTLOG_VERBOSITY -ge 2 && cat $LOGS_DIR/advanced_k_funcstrargs_script.err
# checking for the perf script output sanity
REGEX_SCRIPT_LINE="\s*cat\s+$RE_NUMBER\s+\[$RE_NUMBER\]\s+$RE_NUMBER:\s+probe:do_sys_open(?:_\d+)?:\s+\($RE_NUMBER_HEX\) filename_string=\"$RE_PATH\""
../common/check_all_lines_matched.pl "$REGEX_SCRIPT_LINE" < $LOGS_DIR/advanced_k_funcstrargs_script.log
CHECK_EXIT_CODE=$?

# checking whether the opened file's name (/proc/cmdline) has been recorded/reported by perf
../common/check_all_patterns_found.pl "$FILE_TO_BE_OPEN" < $LOGS_DIR/advanced_k_funcstrargs_script.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "function string argument kprobing :: script"
(( TEST_RESULT += $? ))

fi


clear_all_probes


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
