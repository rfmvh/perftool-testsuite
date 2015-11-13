#
#	test_listing of perf_probe test
#	Author: Michael Petlan <mpetlan@redhat.com>
#	Author: Masami Hiramatsu <masami.hiramatsu.pt@hitachi.com>
#
#	Description:
#
#		This test tests various listings of the perf-probe command
#

# include working environment
. ../common/settings.sh
. ../common/patterns.sh
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0`
TEST_RESULT=0


### kernel functions list

# the '-F' option should list all the available kernel functions for probing
$CMD_PERF probe -F > listing_kernel_functions.log
PERF_EXIT_CODE=$?

RATE=`../common/check_kallsyms_vs_probes.pl /proc/kallsyms listing_kernel_functions.log`
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "kernel functions list ($RATE to kallsyms)"
(( TEST_RESULT += $? ))


### userspace functions list

# with '-x binary' the '-F' option should inspect the binary instead of kernel
$CMD_PERF probe -x examples/exact_counts -F > listing_userspace_functions.log
PERF_EXIT_CODE=$?

../common/check_all_paterns_found.pl "f_103x" "f_1x" "f_2x" "f_3x" "f_65535x" "f_997x" "main" < listing_userspace_functions.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "userspace functions list"
(( TEST_RESULT += $? ))


### FIXME

# need to add some -V listing for variables, and -L for the line numbers
# both for kernel and userspace

# then there's the -L listing of whole source file that does not work for
# the userspace binaries; maybe that needs a patch in perf


# print overall resutls
print_overall_results "$TEST_RESULT"
exit $?
