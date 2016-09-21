#!/bin/bash

#
#	test_powerpc_hv24x7 of perf_list test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This test tests correct showing of hv_24x7 events.
#	These events are expected to be supported on POWER8 LPAR
#	machines only.
#
#		The 24x7 events used to have the domain they belong
#	to specified in their names, which is not currently true,
#	domain is specified as an argument now. Perf list should
#	show corresponding information.
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0

# ppc64, ppc64le (or ppc64el) only
if ! [[ "$MY_ARCH" =~ ppc64.* ]]; then
	print_overall_skipped
	exit 0
fi

# POWER8 only
LD_SHOW_AUXV=1 /bin/true | grep -q -i POWER8
if [ $? -ne 0 ]; then
	print_overall_skipped
	exit 0
fi

# detect virtualization
type virt-what 2>/dev/null >/dev/null
if [ $? -ne 0 ]; then
	VIRT="unknown"
else
	VIRT=`virt-what`
fi

# we can continue only if VIRT is 'LPAR' or unknown
echo "$VIRT" | grep -q -i -e "lpar" -e "unknown"
if ! [ "$VIRT" = "" -o "$VIRT" = "unknown" ]; then
	print_overall_skipped
	exit 0
fi


### listing hv_24x7 events

# test that perf list is even working
$CMD_PERF list hv_24x7 > $LOGS_DIR/hv_24x7_list.log
PERF_EXIT_CODE=$?

REGEX_HV_ARG=",(?:domain|core)=\?"
REGEX_HV_EVENTNAME="[A-Za-z0-9](?:[A-Za-z0-9]|_[A-Za-z0-9])+"
REGEX_HV_EVENT="hv_24x7\/$REGEX_HV_EVENTNAME(?:$REGEX_HV_ARG)+\/"
REGEX_LINE_BASIC="^\s*$REGEX_HV_EVENT\s+\[Kernel\sPMU\sevent\]"
../common/check_all_lines_matched.pl "$REGEX_LINE_BASIC" < $LOGS_DIR/hv_24x7_list.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "listing events"
(( TEST_RESULT += $? ))


### domain table

# since the domains are specified as an argument, we need a table
DOMAIN_TABLE_FILE=/sys/bus/event_source/devices/hv_24x7/interface/domains
test -e $DOMAIN_TABLE_FILE
CHECK_EXIT_CODE=$?

../common/check_exact_pattern_order.pl "^1:\s" "^2:\s" "^3:\s" "^4:\s" "^5:\s" "^6:\s" < $DOMAIN_TABLE_FILE
(( CHECK_EXIT_CODE += $? ))

../common/check_all_patterns_found.pl "Physical Chip" "Physical Core" "VCPU" "Home" "Node" < $DOMAIN_TABLE_FILE
(( CHECK_EXIT_CODE += $? ))

print_results 0 $CHECK_EXIT_CODE "domain table"
(( TEST_RESULT += $? ))


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
