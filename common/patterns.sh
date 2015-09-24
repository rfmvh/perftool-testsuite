export RE_NUMBER="[0-9\.]+"
# Number
# Examples:
#    123.456


export RE_NUMBER_HEX="[0-9A-Fa-f]+"
# Hexadecimal number
# Examples:
#    1234
#    a58d
#    aBcD
#    deadbeef


export RE_EVENT_ANY="[\w\-\:\/_=,]+"
# Name of any event (universal)
# Examples:
#    cpu-cycles
#    cpu/event=12,umask=34/
#    r41e1
#    nfs:nfs_getattr_enter


export RE_EVENT="[\w\-:_]+"
# Name of an usual event
# Examples:
#    cpu-cycles


export RE_EVENT_RAW="r$RE_NUMBER_HEX"
# Specification of a raw event
# Examples:
#    r41e1
#    r1a


export RE_EVENT_CPU="cpu/(\w=""$RE_NUMBER_HEX"",?)+/p*" # FIXME
# Specification of a CPU event
# Examples:
#    cpu/event=12,umask=34/pp


export RE_EVENT_UNCORE="uncore/[\w_]+/"
# Specification of an uncore event
# Examples:
#    uncore/qhl_request_local_reads/


export RE_EVENT_SUBSYSTEM="[\w\-]+:[\w\-]+"
# Name of an event from subsystem
# Examples:
#    ext4:ext4_ordered_write_end
#    sched:sched_switch

export RE_LINE_COMMENT="^#.*"
# A comment line
# Examples:
#    # Started on Thu Sep 10 11:43:00 2015

export RE_LINE_EMPTY="^\s*$"
# An empty line with possible whitespaces
# Examples:
#

export RE_LINE_RECORD1="^\[\s+perf\s+record:\s+Woken up $RE_NUMBER times? to write data\s+\].*$"
# The first line of perf-record "OK" output
# Examples:
#    [ perf record: Woken up 1 times to write data ]

export RE_LINE_RECORD2="^\[\s+perf\s+record:\s+Captured and wrote $RE_NUMBER\s*MB\s+perf.data\s*\(~?$RE_NUMBER samples\)\s+\].*$"
# The second line of perf-record "OK" output
# Examples:
#    [ perf record: Captured and wrote 0.405 MB perf.data (109 samples) ]

