#FLAGS=-Wall -Wextra -I. -O2
FLAGS=-I. -O2 -ggdb
all: dns_proxy
.PHONY : clean

dns_proxy: dns_proxy.c adt/ac_bm.c common/memstr_func.c common/misc.c common/strcasestr_func.c common/string_s.c common/timestamp.c
	gcc $(FLAGS) -o dns_proxy \
		dns_proxy.c	             \
		adt/ac_bm.c              \
		common/memstr_func.c     \
		common/misc.c            \
		common/strcasestr_func.c \
		common/string_s.c        \
		common/timestamp.c

clean :
	@rm -f dns_proxy

install:
	@cp -f dns_proxy dns_proxy.sh ~/bin/
	@cp -f dns_proxy.conf ~/.dns_proxy.conf
	@cp -f ./resolv_new.conf /usr/local/etc/dns_proxy_resolv.conf
	@echo install OK

uninstall:
	@rm -f ~/bin/dns_proxy ~/bin/dns_proxy.sh ~/.dns_proxy.conf /usr/local/etc/dns_proxy_resolv.conf
	@echo uninstall OK
