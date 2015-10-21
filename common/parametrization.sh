#
#	parametrization.sh
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This file configures the testcases how deeply they should
#	look at things. The parametrization allows you to use the suite
#	for both smoke testing and deeper testing.
#

#### perf_stat

# If set, the 24x7 events will be tested on all available cores.
# That might make it 'nproc' times longer. Basically it should be
# enough to run each event on one core only.
# Note: POWER8 only
export PARAM_STAT_24x7_ALL_CORES=n
