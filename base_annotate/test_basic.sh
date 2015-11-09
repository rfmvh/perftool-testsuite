#
#	test_basic of perf annotate test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This test tests basic functionality of perf annotate command.
#
#

# include working environment
. ../common/settings.sh
. ../common/patterns.sh
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0`
TEST_RESULT=0


### help message

# test that a help message is shown and looks reasonable
$CMD_PERF annotate --help > basic_helpmsg.log
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "PERF-ANNOTATE" "NAME" "SYNOPSIS" "DESCRIPTION" "OPTIONS" "SEE ALSO" < basic_helpmsg.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "perf\-annotate \- Read perf.data .* display annotated code" < basic_helpmsg.log
(( CHECK_EXIT_CODE += $? ))
../common/check_all_patterns_found.pl "input" "dsos" "symbol" "force" "verbose" "dump-raw-trace" "vmlinux" "modules" < basic_helpmsg.log
(( CHECK_EXIT_CODE += $? ))
../common/check_all_patterns_found.pl "print-line" "full-paths" "stdio" "tui" "cpu" "source" "symfs" "disassembler-style" < basic_helpmsg.log
(( CHECK_EXIT_CODE += $? ))
../common/check_all_patterns_found.pl "objdump" "skip-missing" "group" < basic_helpmsg.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "help message"
(( TEST_RESULT += $? ))


### basic execution

# annotate...
$CMD_PERF annotate --stdio > basic_annotate.log 2> basic_annotate.err
PERF_EXIT_CODE=$?

# check the annotate output; default option means both source and assembly
REGEX_HEADER="Percent.*Source code.*Disassembly\sof"
REGEX_LINE="$RE_NUMBER\s+:\s+$RE_NUMBER_HEX\s*:.*"
REGEX_SECTION__TEXT="Disassembly of section \.text:"
# check for the basic structure
../common/check_all_patterns_found.pl "$REGEX_HEADER load" "$REGEX_LINE" "$REGEX_SECTION__TEXT" < basic_annotate.log
CHECK_EXIT_CODE=$?
# check for the source code presence
../common/check_all_patterns_found.pl "main" "from = atol" "from = 20L;" "for\s*\(i = 1L; j; \+\+i\)" "return 0;" < basic_annotate.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "basic execution - annotate"
(( TEST_RESULT += $? ))


### dso filter

# '--dso SOME_DSO' limits the annotation to SOME_DSO only
$CMD_PERF annotate --stdio --dso load > basic_dso.log 2> basic_dso.err
PERF_EXIT_CODE=$? 

../common/check_all_patterns_found.pl "$REGEX_HEADER load" "$REGEX_LINE" "$REGEX_SECTION__TEXT" < basic_dso.log
CHECK_EXIT_CODE=$?
# check for the source code presence
../common/check_all_patterns_found.pl "main\(" "from = atol" "from = 20L;" "for\s*\(i = 1L; j; \+\+i\)" "return 0;" < basic_dso.log
(( CHECK_EXIT_CODE += $? ))
# check whether the '--dso' option cuts the output to one dso only
test `grep -c "Disassembly" basic_dso.log` -eq 2
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "dso filter"
(( TEST_RESULT += $? ))


### no-source

# '--no-source' should show only the assembly code
$CMD_PERF annotate --stdio --no-source --dso load > basic_nosource.log 2> basic_nosource.err
PERF_EXIT_CODE=$? 

../common/check_all_patterns_found.pl "$REGEX_HEADER load" "$REGEX_LINE" "$REGEX_SECTION__TEXT" < basic_nosource.log
CHECK_EXIT_CODE=$?
# the C source should not be there
../common/check_no_patterns_found.pl "from = atol" "from = 20L;" "for\s*\(i = 1L; j; \+\+i\)" "return 0;" < basic_nosource.log
(( CHECK_EXIT_CODE += $? ))
# check whether the '--dso' option cuts the output to one dso only
test `grep -c "Disassembly" basic_dso.log` -eq 2
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "no-source"
(( TEST_RESULT += $? ))


### full-paths

# '-P' should print full paths of DSOs
$CMD_PERF annotate --stdio --dso load -P > basic_fullpaths.log 2> basic_fullpaths.err
PERF_EXIT_CODE=$?

FULLPATH="`pwd`/examples"
../common/check_all_patterns_found.pl "$REGEX_HEADER $FULLPATH/load" "$REGEX_LINE" "$REGEX_SECTION__TEXT" < basic_fullpaths.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "full-paths"
(( TEST_RESULT += $? ))


### redirected input

# '-i dir/perf.data' should point to some other perf.data file
mv perf.data examples/
$CMD_PERF annotate --stdio --dso load -i examples/perf.data > basic_input.log 2> basic_input.err
PERF_EXIT_CODE=$?

# the output should be the same as before
diff -q basic_input.log basic_dso.log
CHECK_EXIT_CODE=$?
diff -q basic_input.err basic_dso.err
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "redirected input"
(( TEST_RESULT += $? ))


### execution without perf.data

# test that perf list is even working
! $CMD_PERF annotate > basic_nodata.log 2> basic_nodata.err
PERF_EXIT_CODE=$?

REGEX_NO_DATA="failed to open perf.data: No such file or directory"
../common/check_all_lines_matched.pl "$REGEX_NO_DATA" < basic_nodata.err
CHECK_EXIT_CODE=$?
test ! -s basic_nodata.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "execution without data"
(( TEST_RESULT += $? ))
mv examples/perf.data ./


# print overall resutls
print_overall_results "$TEST_RESULT"
exit $?
