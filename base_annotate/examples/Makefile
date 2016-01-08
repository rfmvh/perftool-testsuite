CC=gcc
CFLAGS=-g -O0

SRCS = $(wildcard *.c)
PROGS = $(patsubst %.c,%,$(SRCS))

all: $(PROGS)
ifneq "$(MAKE_TARGET_DIR)x" 'x'
	mv $(PROGS) $(MAKE_TARGET_DIR)/
endif

%: %.c
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -f $(PROGS)
