allobj=simple multithread multi-single multi_test
all: $(allobj)
CC=gcc
CFLAGS=-O2 -Wall -Werror 
#-DDEBUG
LDFLAGS=-lcurl -lpthread -lcrypto
COMMON_OBJS=setsignal.o  ssl_lock.o  timestamp.o  util.o

simple: simple.o

multithread: multithread.o timestamp.o setsignal.o ssl_lock.o

multi-single: multi-single.o

multi_test: multi_test.o $(COMMON_OBJS)

clean:
	rm -f $(allobj) *.o
