#!/bin/bash -

valgrind --leak-check=yes --show-reachable=yes --max-stackframe=2064048 $@
#--log-file=valgrind.log 

