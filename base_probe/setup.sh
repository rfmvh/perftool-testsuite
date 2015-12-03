#!/bin/bash

#
#	setup.sh of perf probe test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		We need to clean-up all the previously added probes
#		FIXME
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`

make -s -C examples

print_results $? 0 "building examples"
exit $?
