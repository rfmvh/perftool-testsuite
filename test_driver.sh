#
#	test_driver.sh
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#		The test_driver runs all the tests.
#
#

. common/settings.sh

# FIXME :: add arguments for logging, test depth, etc
export PERFTEST_LOGGING=${PERFTEST_LOGGING:-n}

#### specifies the sets of test per architecture
declare -A TESTING_SET

TESTING_SET['aarch64']="stat"
TESTING_SET['ppc64']="stat"
TESTING_SET['ppc64le']="stat"
TESTING_SET['s390x']="stat"
TESTING_SET['x86_64']="stat"
TESTING_SET['i686']="stat"


#### show something about the environment
export ARCH=`arch`
export KERNEL=`uname -r`
export NPROC=`nproc`
echo "======================================================"
echo "Kernel: $KERNEL"
echo "Architecture: $ARCH"
echo "CPU Info:"
head -n 25 /proc/cpuinfo | while read line; do echo -e "\t$line"; done; unset line
echo "AT_PLATFORM:"
LD_SHOW_AUXV=1 /bin/true | grep PLATFORM | while read line; do echo -e "\t$line"; done; unset line
if [[ $ARCH =~ ppc64.* ]]; then
	export VIRTUALIZATION=`systemd-detect-virt -q && echo PowerKVM || ( test -e /proc/ppc64/lparcfg && echo PowerVM || echo none )`                
else
	VIRTUALIZATION=`virt-what`
	export VIRTUALIZATION=${VIRTUALIZATION:-none}
fi
echo "Virtualization: $VIRTUALIZATION"
echo "PERF: $CMD_PERF"
echo "======================================================"; echo; echo

#### init
SUBTESTS_TO_RUN="${TESTING_SET[$ARCH]}"
if [ "$PERFTEST_LOGGING" = "y" ]; then
	test -d LOGS && rm -rf LOGS
	mkdir LOGS
	export LOGS_DIR=`pwd`/LOGS

	# print header
	echo "============= Running tests ============="
fi

FAILED_COUNT=0
PASSED_COUNT=0

#### run the tests
for subtest in $SUBTESTS_TO_RUN; do
	SUBTEST_RESULT=0
	cd base_$subtest
	if [ "$PERFTEST_LOGGING" = "y" ]; then
		mkdir $LOGS_DIR/$subtest
		export LOGGING="> $LOGS_DIR/$subtest/"
	else
		# print header
		echo "========================= $subtest ========================="
	fi


	# setup, if necessary
	test -e setup.sh && eval ./setup.sh $LOGGING/setup.log || true
	(( SUBTEST_RESULT += $?))

	# run all the available testcases
	for testcase in test_*sh; do
		eval ./$testcase $LOGGING/`basename $testcase .sh`.log
		(( SUBTEST_RESULT += $?))
	done

	# cleanup, if necessary
	test -e cleanup.sh && eval ./cleanup.sh $LOGGING/cleanup.log || true
	(( SUBTEST_RESULT += $?))

	cd ..

	# print result
	if [ "$PERFTEST_LOGGING" = "y" ]; then
		if [ $SUBTEST_RESULT -eq 0 ]; then
			echo -e "$MALLPASS## [ PASS ] ##$MEND $subtest"
			(( PASSED_COUNT += 1 ))
		else
			echo -e "$MALLFAIL## [ FAIL ] ##$MEND $subtest"
			(( FAILED_COUNT += 1 ))
		fi
	else
		echo; echo
	fi
done

