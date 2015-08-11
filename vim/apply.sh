#!/bin/bash -
#===============================================================================
#          FILE: apply.sh
#         USAGE: ./apply.sh
#   DESCRIPTION:
#        AUTHOR: dengwei
#       CREATED: 2015年07月19日 00:54
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

cp vimrc ~/.vimrc
mkdir ~/.vim
cp -r bundle ~/.vim/
