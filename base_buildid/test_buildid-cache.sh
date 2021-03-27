#!/bin/bash

#
#       test_buildid-cache of perf buildid test
#       Author: Benjamin Salon <bsalonn@redhat.com>
#
#       Description:
#
#               This test checks tests functionality of perf buildid-cache
#       command, which manages buildid-cache.
#

# include working environment
. ../common/init.sh
. ./settings.sh

TEST_RESULT=0

### run the setup
source setup_src.sh

# the test name needs to be reset here
THIS_TEST_NAME=`basename $0 .sh`


### help message

if [ "$PARAM_GENERAL_HELP_TEXT_CHECK" = "y" ]; then
        # test that a help message is shown and looks reasonable
        $CMD_PERF buildid-cache --help > $LOGS_DIR/list_helpmsg.log
        PERF_EXIT_CODE=$?

        ../common/check_all_patterns_found.pl "PERF-BUILDID-CACHE" "NAME" "SYNOPSIS" "DESCRIPTION" "OPTIONS" "SEE ALSO" < $LOGS_DIR/list_helpmsg.log
        CHECK_EXIT_CODE=$?
        ../common/check_all_patterns_found.pl "perf\-buildid\-cache \- Manage build\-id cache\." < $LOGS_DIR/list_helpmsg.log
        (( CHECK_EXIT_CODE += $? ))

        print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "help message"
        (( TEST_RESULT += $? ))
else
        print_testcase_skipped "help message"
fi


### buildids check

# test that perf buildid-cache --list works
$CMD_PERF --buildid-dir $BUILDIDDIR buildid-cache -l > $LOGS_DIR/cache_list.log 2> $LOGS_DIR/cache_list.err
PERF_EXIT_CODE=$?

# output sanity checks
REGEX_LINE_BASIC="\w{40}\s+$RE_PATH"
REGEX_LINE_KALLSYMS="\w{40}\s+\[kernel\.kallsyms\]"
REGEX_LINE_VDSO="\w{40}\s+\[\w+\]"
../common/check_all_lines_matched.pl "$REGEX_LINE_BASIC" "$REGEX_LINE_KALLSYMS" "$REGEX_LINE_VDSO" < $LOGS_DIR/cache_list.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "$REGEX_LINE_BASIC" < $LOGS_DIR/cache_list.log
(( CHECK_EXIT_CODE += $? ))

# error output should be empty
test ! -s $LOGS_DIR/cache_list.err
(( CHECK_EXIT_CODE += $? ))

# output semantics check
if support_buildids_vs_files_check; then
	../common/check_buildids_vs_files.pl < $LOGS_DIR/cache_list.log
	(( CHECK_EXIT_CODE += $? ))
fi

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "list"
(( TEST_RESULT += $? ))


### check $HOME/.debug-`date +%s` ($BUILDIDDIR) structure

# hex numbers are "stored" in elf files
cat $LOGS_DIR/cache_list.log | perl -ne 'BEGIN{$BUILDIDDIR=shift;} print "$1 ${BUILDIDDIR}$2/$1/elf\n" if /^(\w{40})\s+((\/[\w\+.-]+)+)$/; print "$1 ${BUILDIDDIR}/$2/$1/elf\n" if /^(\w{40})\s+(\[[\w\.]+\])$/' $BUILDIDDIR > $LOGS_DIR/cache_debug_structure.log
CHECK_EXIT_CODE=$?

if support_buildids_vs_files_check; then
	../common/check_buildids_vs_files.pl < $LOGS_DIR/cache_debug_structure.log
	(( CHECK_EXIT_CODE += $? ))
fi

print_results 0 $CHECK_EXIT_CODE "check $BUILDIDDIR structure"
(( TEST_RESULT += $? ))


### remove test

# let's pick some files to remove
COUNT=`cat $LOGS_DIR/cache_list.log | wc -l`
(( PART = COUNT / 2 ))
test $PART -gt 4 && PART=4

REMOVED_FILES=`awk '{print $2}' < $LOGS_DIR/cache_list.log | ../common/pick_random.pl $PART`

# remove files
PERF_EXIT_CODE=0
for FILE in $REMOVED_FILES; do
	$CMD_PERF --buildid-dir $BUILDIDDIR buildid-cache -r $FILE
	(( PERF_EXIT_CODE += $? ))
done

$CMD_PERF --buildid-dir $BUILDIDDIR buildid-cache -l > $LOGS_DIR/cache_remove_list.log 2> $LOGS_DIR/cache_remove_list.err
(( PERF_EXIT_CODE += $? ))

# check if were the files removed
CHECK_EXIT_CODE=0
for FILE in $REMOVED_FILES; do
        cat $LOGS_DIR/cache_remove_list.log | grep -q $FILE
        test $? -ne 0
        (( CHECK_EXIT_CODE += $? ))
done

# check if there still are some files
../common/check_all_patterns_found.pl "$REGEX_LINE_BASIC" < $LOGS_DIR/cache_remove_list.log
(( CHECK_EXIT_CODE += $? ))
REMAINING_LINES=`cat $LOGS_DIR/cache_remove_list.log | wc -l`
(( EXPECTED_LINES = REMAINING_LINES + PART ))
test $EXPECTED_LINES -eq $COUNT
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "remove test"
(( TEST_RESULT += $? ))


### add test

# add removed files
PERF_EXIT_CODE=0
for FILE in $REMOVED_FILES; do
	$CMD_PERF --buildid-dir $BUILDIDDIR buildid-cache -a $FILE
	(( PERF_EXIT_CODE += $? ))
done

$CMD_PERF --buildid-dir $BUILDIDDIR buildid-cache -l > $LOGS_DIR/cache_added_list.log 2> $LOGS_DIR/cache_added_list.err
(( PERF_EXIT_CODE += $? ))

# check if were the files added
CHECK_EXIT_CODE=0
for FILE in $REMOVED_FILES; do
	cat $LOGS_DIR/cache_added_list.log | grep -q $FILE
	(( CHECK_EXIT_CODE += $? ))
done

ALL_LINES=`cat $LOGS_DIR/cache_added_list.log | wc -l`
test $ALL_LINES -eq $COUNT
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "add test"
(( TEST_RESULT += $? ))


### missing build ids test

# get new build ids
$CMD_PERF record -a -o $CURRENT_TEST_DIR/perfnew.data -- $CMD_LONGER_SLEEP &> /dev/null
PERF_EXIT_CODE=$?

MISSING_IDS=`$CMD_PERF --buildid-dir $BUILDIDDIR buildid-cache -M $CURRENT_TEST_DIR/perfnew.data 2> /dev/null`
(( PERF_EXIT_CODE += $? ))

if [ -z "$MISSING_IDS" ]; then
	print_testcase_skipped "missing buildid test (nothing was missing)"
else
	# check if the missing buildids not in cache
	CHECK_EXIT_CODE=0
	for BUILDID in $MISSING_IDS; do
		cat $LOGS_DIR/cache_added_list.log | grep -q $BUILDID
		test $? -ne 0
		(( CHECK_EXIT_CODE += $? ))
	done

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "missing buildid test"
	(( TEST_RESULT += $? ))
fi


### update test

# create a simple binary file
echo "int main(void) { return 0; }" | gcc -o $CURRENT_TEST_DIR/empty -xc -O1 - &> /dev/null

$CMD_PERF buildid-cache -a $CURRENT_TEST_DIR/empty
PERF_EXIT_CODE=$?
BUILDID_BEFORE=`$CMD_PERF buildid-cache -l | grep $CURRENT_TEST_DIR/empty`
CHECK_EXIT_CODE=$?

# update the created file
echo "int main(void) { return 0; }" | gcc -o $CURRENT_TEST_DIR/empty -xc -O2 - &> /dev/null

$CMD_PERF buildid-cache -u $CURRENT_TEST_DIR/empty
(( PERF_EXIT_CODE += $? ))
BUILDID_AFTER=`$CMD_PERF buildid-cache -l | grep $CURRENT_TEST_DIR/empty`
(( CHECK_EXIT_CODE += $?))

# buildids should be different
test "$BUILDID_BEFORE" != "$BUILDID_AFTER"
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "update file test"
(( TEST_RESULT += $?))


### purge test

# let's pick some files to remove
COUNT=`cat $LOGS_DIR/cache_list.log | wc -l`
(( PART = COUNT / 2 ))
test $PART -gt 3 && PART=3

PURGED_FILES=`awk '{print $2}' < $LOGS_DIR/cache_added_list.log | ../common/pick_random.pl $PART`

# purge files
PERF_EXIT_CODE=0
for FILE in $PURGED_FILES; do
	$CMD_PERF --buildid-dir $BUILDIDDIR buildid-cache -p $FILE
	(( PERF_EXIT_CODE += $? ))
done

$CMD_PERF --buildid-dir $BUILDIDDIR buildid-cache -l > $LOGS_DIR/cache_purge_list.log 2> $LOGS_DIR/cache_purge_list.err
(( PERF_EXIT_CODE += $? ))

# check if were the files purged
CHECK_EXIT_CODE=0
for FILE in $PURGED_FILES; do
        cat $LOGS_DIR/cache_purge_list.log | grep -q $FILE
        test $? -ne 0
        (( CHECK_EXIT_CODE += $? ))
done

# check if there still are some files
../common/check_all_patterns_found.pl "$REGEX_LINE_BASIC" < $LOGS_DIR/cache_purge_list.log
(( CHECK_EXIT_CODE += $? ))
REMAINING_LINES=`cat $LOGS_DIR/cache_purge_list.log | wc -l`
(( EXPECTED_LINES = REMAINING_LINES + PART ))
test $EXPECTED_LINES -eq $COUNT
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "purge test"
(( TEST_RESULT += $? ))


### purge all test

$CMD_PERF --buildid-dir $BUILDIDDIR buildid-cache -P &> /dev/null
PERF_EXIT_CODE=$?

$CMD_PERF --buildid-dir $BUILDIDDIR buildid-cache -l > $LOGS_DIR/cache_purgeall_list.log 2> $LOGS_DIR/cache_purgeall_list.err
(( PERF_EXIT_CODE += $? ))

# check if was the cache flushed
test ! -s $LOGS_DIR/cache_purgeall_list.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "purge all test"
(( TEST_RESULT += $? ))


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
