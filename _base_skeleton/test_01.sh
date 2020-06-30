#!/bin/bash

#
#	test_01 of SKELETON test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#		FIXME
#
#

. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0


# testcases

# format:
# print_results $PERF_COMMAND_EXIT_CODE $REGEXP_PARSER_EXIT_CODE "comment (subtest name, etc...)"

print_warning "something went wrong in setup"

print_results 0 0 "some passing test 01"
(( TEST_RESULT += $? ))

print_results 0 0 "some passing test 02"
(( TEST_RESULT += $? ))

print_results 1 0 "some test failing on perf command"
(( TEST_RESULT += $? ))

print_results 0 1 "some test failing on parsing output"
(( TEST_RESULT += $? ))

print_results 1 1 "some completely failing test"
(( TEST_RESULT += $? ))

# print results
print_overall_results 3
