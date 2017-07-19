CC=gcc
CFLAGS=-g -O0
CPP=g++
CPPFLAGS=-g -fno-omit-frame-pointer
ALLOPTS=0 1 2 3 s fast g

SRCS = $(wildcard *.c)
PROGS = $(patsubst %.c,%,$(SRCS))

all: $(PROGS) test_opts simple_threads
ifneq "$(MAKE_TARGET_DIR)x" 'x'
	mv $(PROGS) $(MAKE_TARGET_DIR)/
	mv test_opts_* $(MAKE_TARGET_DIR)/
	mv simple_threads $(MAKE_TARGET_DIR)/
endif

%: %.c
	$(CC) $(CFLAGS) -o $@ $<

test_opts: test_opts.cc
	$(foreach opt, $(ALLOPTS), $(CPP) $(CPPFLAGS) -O$(opt) -o test_opts_$(opt) test_opts.cc;)

simple_threads: simple_threads.cc
	$(CC) $(CFLAGS) -o simple_threads -pthread simple_threads.cc

clean:
	rm -f $(PROGS) test_opts_* simple_threads
