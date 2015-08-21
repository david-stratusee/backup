#!/bin/bash -
#===============================================================================
#          FILE: git_commit.sh
#         USAGE: ./git_commit.sh
#   DESCRIPTION:
#        AUTHOR: dengwei
#       CREATED: 07/21/2014 16:30
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

function Usage()
{
    echo "Usage: `basename $1` [add|rm] [-m msg|-F msgfile] files..."
    echo "   or: `basename $1` [add|rm] [-m msg|-F msgfile] -f conf_file"
}

if [ $# -lt 4 ]; then
    Usage $0
    exit
fi

if [ "$2" != "-m" ] && [ "$2" != "-F" ]; then
    Usage $0
    exit
fi

if [ ! -d .git ] && [ ! -d ../.git ] && [ ! -d ../../.git ] && [ ! -d ../../../.git ] && [ ! -d ../../../../.git ] && [ ! -d ../../../../../.git ]; then
    echo "You are not in one git repository"
    exit 0
fi

action=$1
msgact=$2
msg=$3

if [ "$action" != "add" ] && [ "$action" != "rm" ]; then
    Usage $0
    exit
elif [ "$action" == "rm" ]; then
    action="rm -r"
fi

# for add|rm
shift

#for -m
shift

#for msg
shift

list=$@
if [ "$1" == "-f" ]; then
    # read from file
    list=`cat "$2"`
fi

echo git $action $list
git $action $list
echo git commit ${msgact} \"${msg}\" $list
git commit ${msgact} "${msg}" $list

