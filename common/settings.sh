#
#	settings.sh
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This file contains global settings for the whole testsuite.
#	Its purpose is to make it easier when it is necessary i.e. to
#	change the usual sample command which is used in all of the tests
#	in many files.
#
#		This file is intended to be sourced in the tests.
#

#### which perf to use in the testing
export CMD_PERF=${CMD_PERF:-`which perf`}

#### basic programs examinated by perf
export CMD_BASIC_SLEEP="sleep 0.1"
export CMD_QUICK_SLEEP="sleep 0.01"
export CMD_LONGER_SLEEP="sleep 2"
export CMD_VERY_LONG_SLEEP="sleep 30"
export CMD_SIMPLE="true"

#### common settings
export TESTLOG_VERBOSITY=${TESTLOG_VERBOSITY:-0}
export ERROR_MESSAGE_MAX_LINES=${ERROR_MESSAGE_MAX_LINES:-20}

#### clear locale
export LC_ALL=C

#### colors
if [ -t 1 ]; then
	export MPASS="\e[32m"
	export MALLPASS="\e[1;32m"
	export MFAIL="\e[31m"
	export MALLFAIL="\e[1;31m"
	export MWARN="\e[1;35m"
	export MSKIP="\e[33m"
	export MHIGH="\e[1;33m"
	export MEND="\e[m"
else
	export MPASS=""
	export MALLPASS=""
	export MFAIL=""
	export MALLFAIL=""
	export MWARN=""
	export MSKIP=""
	export MHIGH=""
	export MEND=""
fi


#### test parametrization
if [ ! -d ./common ]; then
	# FIXME nasty hack
	. ../common/parametrization.sh
fi
