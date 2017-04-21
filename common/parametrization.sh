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

#### general

# If set, the '--help' outputs of the commands will be checked.
# Since the '--help' option calls a manpage and manpages are not
# always generated, you may skip the man-page checks.
export PARAM_GENERAL_HELP_TEXT_CHECK=${PARAM_GENERAL_HELP_TEXT_CHECK:-n}


#### perf_stat

# If set, the 24x7 events will be tested on all available cores.
# That might make it 'nproc' times longer. Basically it should be
# enough to run each event on one core only.
# Note: POWER8 only
export PARAM_STAT_24x7_ALL_CORES=${PARAM_STAT_24x7_ALL_CORES:-n}

# If set, the 24x7 events will be tested on all available domains.
# Domain list: /sys/bus/event_source/devices/hv_24x7/interface/domains
# Default "n" value means that only domains "1 2" are tested.
export PARAM_STAT_24x7_ALL_DOMAINS=${PARAM_STAT_24x7_ALL_DOMAINS:-n}

# If set, all the tracepoint events will be checked for syntax
# errors in their definition. This testcase may take a long time
# and the checks are not that crucial, so it can be turned off
# when you do not want to deep dive.
export PARAM_STAT_TRACEPOINT_EVENTS_SYNTAX=${PARAM_STAT_TRACEPOINT_EVENTS_SYNTAX:-n}


#### perf_trace

# If set, some heavy load tests are run. That might be not always
# desired behaviour.
export PARAM_TRACE_OVERLOAD=${PARAM_TRACE_OVERLOAD:-y}


#### perf_record

# If set, some heavy load tests are run. That might be not always
# desired behaviour.
export PARAM_RECORD_OVERLOAD=${PARAM_RECORD_OVERLOAD:-n}

# If set to "y", "fp" callgraph will be used in perf-record overhead
# test; if set to "n", it will not be used. If not set/empty, it will
# maybe run and maybe not.
export PARAM_RECORD_CALLGRAPH_FP=${PARAM_RECORD_CALLGRAPH_FP:-y}

# If set to "y", "dwarf" callgraph will be used in perf-record overhead
# test; if set to "n", it will not be used. If not set/empty, it will
# run depending on architecture (default behavior).
export PARAM_RECORD_CALLGRAPH_DWARF=${PARAM_RECORD_CALLGRAPH_DWARF:-}
