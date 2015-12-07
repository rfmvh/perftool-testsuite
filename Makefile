#
#	Makefile
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#		A Makefile for building of the run_all.c
#	and running the whole suite by "make check"
#
#

CC=gcc
CFLAGS=-g -O0

.PHONY: all pack clean

all: run_all check

clean:
	rm -f run_all

pack:
	tar c `git ls-tree -r master --name-only` | xz > perftool-testsuite.tar.xz

check: run_all
	./run_all -v

run_all: run_all.c
	$(CC) $(CFLAGS) -o run_all run_all.c

