#
#	cleanup.sh of perf probe test
#	Author: Michael Petlan <mpetlan@redhat.com>
#	Author: Masami Hiramatsu <masami.hiramatsu.pt@hitachi.com>
#
#

# include working environment
. ../common/settings.sh
. ../common/patterns.sh
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`

clear_all_probes
find . -name \*.log | xargs rm
find . -name \*.err | xargs rm
make -C examples clean

print_results 0 0 "clean-up - removing all probes and deleting logs"
exit $?
