#!/bin/bash

#
#	setup.sh of perf list test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		FIXME - maybe the setup is not necessary
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`

print_overall_results 0
exit $?
