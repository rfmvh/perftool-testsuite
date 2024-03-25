#### !!! THIS IS TO BE SOURCED BY test_scripts.sh !!!

### test for export-to-sqlite script

# export-to-sqlite script exports perf data to a sqlite3 database

script="export-to-sqlite"


# record
$CMD_PERF script record $script -a -o $CURRENT_TEST_DIR/perf.data -- dd if=/dev/zero of=/dev/null bs=1 count=100 2> $LOGS_DIR/script__${script}__record.log
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "perf.data" < $LOGS_DIR/script__${script}__record.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script $script :: record"
(( TEST_RESULT += $? ))


# we must have PySide package installed to test other features
if ! detect_Qt_Python_bindings; then
	return 0
fi

# report

# export-to-sqlite has no option for input file
cd $CURRENT_TEST_DIR || true
$CMD_PERF script report $script $LOGS_DIR/script__${script}__database.data > $LOGS_DIR/script__${script}__report.log 2> /dev/null
PERF_EXIT_CODE=$?
cd $OLDPWD || true

REGEX_PROCESSING_LINE="^\d+-\d+-\d+\s\d+:\d+:${RE_NUMBER}\s[\w .]+"

../common/check_all_lines_matched.pl "$REGEX_PROCESSING_LINE" < $LOGS_DIR/script__${script}__report.log
CHECK_EXIT_CODE=$?
../common/check_exact_pattern_order.pl "Creating database" "Writing records" "Adding indexes" "Dropping unused tables" "Done" < $LOGS_DIR/script__${script}__report.log
(( CHECK_EXIT_CODE += $? ))


rm $LOGS_DIR/script__${script}__database.data
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script $script :: report"
(( TEST_RESULT += $? ))
