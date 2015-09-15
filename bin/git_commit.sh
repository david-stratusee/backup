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
    echo "Usage: `basename $1` -a [add|rm] -f [-m msg] files..."
    echo "   or: `basename $1` -a [add|rm] -f [-m msg] -l file_list"
}

force=""
action=""
msg=""
file_list=""
while getopts 'm:l:a:fh' opt; do
    case $opt in
        m)
            if [ -f $OPTARG ]; then
                msg="-F \"$OPTARG\""
            else
                msg="-m \"$OPTARG\""
            fi
            ;;
        l)
            if [ -f $OPTARG ]; then
                file_list=`cat "$OPTARG"`
            fi
            ;;
        f)
            force=" -f"
            ;;
        a)
            action=$OPTARG
            ;;
        h)
            Usage $0
            exit 0
            ;;
        *)
            Usage $0
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))  #This tells getopts to move on to the next argument.

if [ "$file_list" == "" ]; then
    file_list=$@
fi
if [ "$file_list" == "" ]; then
    echo "no file to commit, use -l to set"
    Usage $0
    exit 1
fi

if [ "$msg" == "" ]; then
    echo "message error, use -m to set"
    Usage $0
    exit 1
fi

if [ "$action" != "add" ] && [ "$action" != "rm" ]; then
    echo "action error, use -a to set"
    Usage $0
    exit 1
elif [ "$action" == "rm" ]; then
    action="rm -r"
fi

if [ ! -d .git ] && [ ! -d ../.git ] && [ ! -d ../../.git ] && [ ! -d ../../../.git ] && [ ! -d ../../../../.git ] && [ ! -d ../../../../../.git ]; then
    echo "You are not in one git repository"
    exit 0
fi

echo git $action$force $file_list
git $action$force $file_list
echo git commit ${msg} $file_list
git commit ${msg} $file_list
