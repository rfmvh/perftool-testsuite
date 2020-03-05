#### !!! THIS IS TO BE SOURCED BY test_scripts.sh !!!

### test for rwtop script

# rwtop script displays system-wide read and write call activity


script="rwtop"


# record
$CMD_PERF script record $script -o $CURRENT_TEST_DIR/perf.data -- dd if=/dev/zero of=/dev/null bs=1 count=0 2> $LOGS_DIR/script__${script}__record.log
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "perf.data" < $LOGS_DIR/script__${script}__record.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script $script :: record"
(( TEST_RESULT += $? ))


# report
$CMD_PERF script report $script -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/script__${script}__report.log 2> $LOGS_DIR/script__${script}__report.err
PERF_EXIT_CODE=$?

REGEX_READ_HEADER1="read counts by pid:"
REGEX_READ_HEADER2="\s+pid\s+comm\s+#\sreads\s+bytes_req\s+bytes_read"
REGEX_READ_LINE="\s*\d+\s+[\w\-\_]+\s+\d+\s+\d+\s+\d+"
REGEX_WRITE_HEADER1="write counts by pid:"
REGEX_WRITE_HEADER2="\s+pid\s+comm\s+#\swrites\s+bytes_written"
REGEX_WRITE_LINE="\s*\d+\s+[\w\-\_]+\s+\d+\s+\d+\s+"

../common/check_all_patterns_found.pl "$REGEX_READ_HEADER1" "$REGEX_READ_HEADER2" "$REGEX_WRITE_HEADER1" "$REGEX_WRITE_HEADER2" < $LOGS_DIR/script__${script}__report.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "$REGEX_READ_LINE" "$REGEX_WRITE_LINE" < $LOGS_DIR/script__${script}__report.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script $script :: report"
(( TEST_RESULT += $? ))


# requested and written bytes check
$CMD_PERF script -F event,trace > $LOGS_DIR/script__${script}.log 2> /dev/null
(( PERF_EXIT_CODE += $?))

# count all requested bytes from perf script
BYTES_REQUESTED_COUNT=`cat $LOGS_DIR/script__${script}.log | grep syscalls:sys_enter_read | grep -o 'count: 0x[0-9a-fA-F]*' | cut -d' ' -f2 | perl -ne 'BEGIN{$n=0;}{$n += hex $1 if (/(0x[0-9a-fA-F]+)/);} END{print "$n\n";}'`

# take requested bytes from perf report script
BYTES_REQUESTED_REPORT=`perl -ne 'BEGIN{$n=0;$en=0;}{$n+=$1 if ($en&&/\s*\d+\s+\S+\s+\d+\s+(\d+)\s+\d+/);$en=1 if /\s*pid\s+comm\s+# reads\s+bytes_req\s+bytes_read/;$en=0 if /^\s*$/} END{print "$n";}' < $LOGS_DIR/script__${script}__report.log`

test $BYTES_REQUESTED_COUNT -eq $BYTES_REQUESTED_REPORT
print_results $PERF_EXIT_CODE $? "script $script :: bytes requested count check ($BYTES_REQUESTED_REPORT = $BYTES_REQUESTED_COUNT)"
(( TEST_RESULT += $? ))


# count all written bytes from perf script
BYTES_WRITTEN_COUNT=`cat $LOGS_DIR/script__${script}.log | grep syscalls:sys_enter_write | grep -o 'count: 0x[0-9a-fA-F]*' | cut -d' ' -f2 | perl -ne 'BEGIN{$n=0;}{$n += hex $1 if (/(0x[0-9a-fA-F]+)/);} END{print "$n\n";}'`

# take written bytes from perf report script
BYTES_WRITTEN_REPORT=`perl -ne 'BEGIN{$n=0;$en=0;}{$n+=$1 if ($en&&/\s*\d+\s+\S+\s+\d+\s+(\d+)/);$en=1 if /\s*pid\s+comm\s+# writes\s+bytes_written/;$en=0 if /^\s*$/} END{print "$n";}' < $LOGS_DIR/script__${script}__report.log`

test $BYTES_WRITTEN_COUNT -eq $BYTES_WRITTEN_REPORT
print_results $PERF_EXIT_CODE $? "script $script :: bytes written count check ($BYTES_WRITTEN_REPORT = $BYTES_WRITTEN_COUNT)"
(( TEST_RESULT += $? ))


# sample count check
READ_PLUS_CHECK=`perl -ne 'BEGIN{$n=0;$en=0;}{$n+=$1 if ($en&&/\s*\d+\s+\S+\s+(\d+)\s+\d+\s+\d+/);$en=1 if /^\s+pid\s+comm\s+#\s+reads\s+bytes_req\s+bytes_read/;$en=0 if /^\s*$/} END{print "$n";}' < $LOGS_DIR/script__${script}__report.log`

WRITE_PLUS_CHECK=`perl -ne 'BEGIN{$n=0;$en=0;}{$n+=$1 if ($en&&/\s*\d+\s+\S+\s+(\d+)\s+\d+/);$en=1 if /^\s+pid\s+comm\s+#\s+writes\s+bytes_written/;$en=0 if /^\s*$/} END{print "$n";}' < $LOGS_DIR/script__${script}__report.log`

for COUNT in "0" "1" "32" "58" "125" "600"; do
	PERF_EXIT_CDOE=0
	$CMD_PERF script record $script -o $CURRENT_TEST_DIR/perf.data -- dd if=/dev/zero of=/dev/null bs=1024 count=$COUNT 2> $LOGS_DIR/script__${script}__record__${COUNT}.log
	(( PERF_EXIT_CODE += $? ))

	$CMD_PERF script report $script -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/script__${script}__report__${COUNT}.log 2> /dev/null
	(( PERF_EXIT_CODE += $? ))

	READ_COUNT=`perl -ne 'BEGIN{$n=0;$en=0;}{$n+=$1 if ($en&&/\s*\d+\s+\S+\s+(\d+)\s+\d+\s+\d+/);$en=1 if /^\s+pid\s+comm\s+#\s+reads\s+bytes_req\s+bytes_read/;$en=0 if /^\s*$/} END{print "$n";}' < $LOGS_DIR/script__${script}__report__${COUNT}.log`
	(( READ_COUNT -= $READ_PLUS_CHECK ))
	test $COUNT -eq $READ_COUNT
	print_results $PERF_EXIT_CODE $? "script $script :: $COUNT # reads count check ($COUNT == $READ_COUNT)"
	(( TEST_RESULT += $? ))

	WRITE_COUNT=`perl -ne 'BEGIN{$n=0;$en=0;}{$n+=$1 if ($en&&/\s*\d+\s+\S+\s+(\d+)\s+\d+/);$en=1 if /^\s+pid\s+comm\s+#\s+writes\s+bytes_written/;$en=0 if /^\s*$/} END{print "$n";}' < $LOGS_DIR/script__${script}__report__${COUNT}.log`
	(( WRITE_COUNT -= $WRITE_PLUS_CHECK ))
	test $COUNT -eq $WRITE_COUNT
	print_results $PERF_EXIT_CODE $? "script $script :: $COUNT # writes count check ($COUNT == $WRITE_COUNT)"
	(( TEST_RESULT += $? ))

	N_SAMPLES=`perl -ne 'print "$1" if /\((\d+) samples\)/' $LOGS_DIR/script__${script}__record__${COUNT}.log`
	ALL_COUNT=$(( 2 * $WRITE_COUNT + 2 * $READ_COUNT + 2 * $WRITE_PLUS_CHECK + 2 * $READ_PLUS_CHECK ))
	test $N_SAMPLES -eq $ALL_COUNT
	print_results $PERF_EXIT_CODE $? "script $script :: sample count check ($ALL_COUNT = $N_SAMPLES)"
	(( TEST_RESULT += $? ))
done
