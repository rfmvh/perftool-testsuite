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

# test that perf cache list is working
$CMD_PERF --buildid-dir $BUILDIDDIR buildid-cache -l > $LOGS_DIR/cache_buildids.log 2> $LOGS_DIR/cache_buildids.err
PERF_EXIT_CODE=$?

# output sanity checks
REGEX_LINE_BASIC="\w{40}\s+$RE_PATH"
REGEX_LINE_KALLSYMS="\w{40}\s+\[kernel\.kallsyms\]"
REGEX_LINE_VDSO="\w{40}\s+\[\w+\]"
../common/check_all_lines_matched.pl "$REGEX_LINE_BASIC" "$REGEX_LINE_KALLSYMS" "$REGEX_LINE_VDSO" < $LOGS_DIR/cache_buildids.log

CHECK_EXIT_CODE=$?
test ! -s $LOGS_DIR/basic_buildids.err
(( CHECK_EXIT_CODE += $? ))

# output semantics check
../common/check_buildids_vs_files.pl < $LOGS_DIR/cache_buildids.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "buildids check"
(( TEST_RESULT += $? ))


### check $HOME/.debug structure

# hex numbers are "stored" in elf files
cat $LOGS_DIR/cache_buildids.log | perl -ne 'BEGIN{$BUILDIDDIR=shift;} print "$1 ${BUILDIDDIR}$2/$1/elf\n" if /^(\w{40})\s+((\/[\w\+.-]+)+)$/; print "$1 ${BUILDIDDIR}/$2/$1/elf\n" if /^(\w{40})\s+(\[[\w\.]+\])$/' $BUILDIDDIR > $LOGS_DIR/cache_debug_buildids.log
CHECK_EXIT_CODE=$?

../common/check_buildids_vs_files.pl < $LOGS_DIR/cache_debug_buildids.log
(( CHECK_EXIT_CODE += $? ))

print_results 0 $CHECK_EXIT_CODE "buildids check in $HOME/.debug"
(( TEST_RESULT += $? ))


### remove test

# we need only the files
REMOVED_FILES=`cat $LOGS_DIR/cache_buildids.log | head -n 5 | awk '{print $2}'`
CHECK_EXIT_CODE=$?

# remove files
PERF_EXIT_CODE=0
for FILE in $REMOVED_FILES; do
        $CMD_PERF --buildid-dir $BUILDIDDIR buildid-cache -p $FILE
        (( PERF_EXIT_CODE += $? ))
done

$CMD_PERF --buildid-dir $BUILDIDDIR buildid-cache -l > $LOGS_DIR/cache_buildids_removed.log 2> $LOGS_DIR/cache_builddis_removed.err
(( PERF_EXIT_CODE += $? ))

# check if were the files removed
for FILE in $REMOVED_FILES; do
        cat $LOGS_DIR/cache_buildids_removed.log | grep -q $FILE
        test $? -ne 0
        (( CHECK_EXIT_CODE += $? ))
done

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "remove test"
(( TEST_RESULT += $? ))


### add test

# add removed files
PERF_EXIT_CODE=0
for FILE in $PURGED_FILES; do
	$CMD_PERF --buildid-dir $BUILDIDDIR buildid-cache -a $FILE
	(( PERF_EXIT_CODE += $? ))
done

$CMD_PERF --buildid-dir $BUILDIDDIR buildid-cache -l > $LOGS_DIR/cache_buildids_added.log 2> $LOGS_DIR/cache_buildids_added.err
(( PERF_EXIT_CODE += $? ))

# check if were the files added
CHECK_EXIT_CODE=0
for FILE in $PURGED_FILES; do
	cat $LOGS_DIR/cache_buildids_added.log | grep -q $FILE
	(( CHECK_EXIT_CODE += $? ))
done

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "add test"


### missing build ids test

# get new build ids
$CMD_PERF record -a -o $CURRENT_TEST_DIR/perfnew.data -- $CMD_LONGER_SLEEP &> /dev/null
PERF_EXIT_CODE=$?

MISSING_IDS=`$CMD_PERF --buildid-dir $BUILDIDDIR buildid-cache -M $CURRENT_TEST_DIR/perfnew.data 2> /dev/null`
(( PERF_EXIT_CODE += $? ))

# check if the missing buildids not in cache
CHECK_EXIT_CODE=0
for FILE in $MISSING_IDS; do
	cat $LOGS_DIR/cache_buildids_added.log | grep -q $FILE
	test $? -ne 0
	(( CHECK_EXIT_CODE += $? ))
done

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "missing build ids test"


### update test

# get files from buildids
MISSING_FILES=`echo $MISSING_IDS | tr ' ' '\n' | grep /`
CHECK_EXIT_CODE=$?

# update the cache
PERF_EXIT_CODE=0
for FILE in $MISSING_FILES; do
	$CMD_PERF --buildid-dir $BUILDIDDIR buildid-cache -u $FILE
	(( PERF_EXIT_CODE += $? ))
done

$CMD_PERF --buildid-dir $BUILDIDDIR buildid-cache -l > $LOGS_DIR/cache_buildids_missing_added.log 2> $LOGS_DIR/cache_buildids_missing_added.err
(( PERF_EXIT_CODE += $? ))

# check if were the files added
for FILE in $MISSING_FILES; do
        cat $LOGS_DIR/cache_buildids_missing_added.log | grep -q $FILE
        (( CHECK_EXIT_CODE += $? ))
done

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "update file test"


### purge test

# we need only the files
PURGED_FILES=`cat $LOGS_DIR/cache_buildids_missing_added.log | head -n 5 | awk '{print $2}'`
CHECK_EXIT_CODE=$?

PERF_EXIT_CODE=0
for FILE in $PURGED_FILES; do
        $CMD_PERF --buildid-dir $BUILDIDDIR buildid-cache -p $FILE
        (( PERF_EXIT_CODE += $? ))
done

$CMD_PERF --buildid-dir $BUILDIDDIR buildid-cache -l > $LOGS_DIR/cache_buildids_purged.log 2> $LOGS_DIR/cache_builddis_purged.err
(( PERF_EXIT_CODE += $? ))

# check if the files were purged
for FILE in $PURGED_FILES; do
        cat $LOGS_DIR/cache_buildids_purged.log | grep -q $FILE
        test $? -ne 0
        (( CHECK_EXIT_CODE += $? ))
done

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "purge test"
(( TEST_RESULT += $? ))


### purge all test

$CMD_PERF --buildid-dir $BUILDIDDIR buildid-cache -P &> /dev/null
PERF_EXIT_CODE=$?

$CMD_PERF --buildid-dir $BUILDIDDIR buildid-cache -l > $LOGS_DIR/cache_buildids_all_purged.log 2> $LOGS_DIR/cache_buildids_all_purged.err
(( PERF_EXIT_CODE += $? ))

# check if was the cache flushed
test ! -s $LOGS_DIR/cache_buildids_all_purged.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "purge all test"


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
