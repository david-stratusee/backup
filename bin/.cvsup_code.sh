#!/bin/bash
#===============================================================================
#          FILE:  cvsup_code.sh
#   DESCRIPTION:  only cvs up code
# 
#        AUTHOR:  dengwei dengwei@venus.com
#       VERSION:  1.0
#       CREATED:  2011年03月03日 09时20分00秒 CST
#===============================================================================

. tools.sh

function genv_diff()
{
	tmpfile=/tmp/.`whoami`_genv_tmp
	cvs status $1 > $tmpfile

	uptodate=`cat $tmpfile | grep "Status:" | grep "Up-to-date" | wc -l`
	if [ $uptodate -ne 0 ]; then
		# it is up-to-date, not local change
		work_ver=`cat $tmpfile | grep "Working revision:" | awk -F":" '{print $2}' | awk -F" " '{print $1}'`
		work_less=`echo $work_ver | awk -F'.' '{	\
			for (i=1;i<=NF-1;i++) {	\
				printf("%s", $i);	\
			}	\
			printf(".%s", $NF-1);	\
		}'`

		echo "update version: "$work_ver
		echo "last version: "$work_less
		cvs diff -r$work_less -r$work_ver $1 | colordiff
	else
		# local changed
		cvs diff $1 | colordiff
	fi

	rm -f $tmpfile
}

function cvsup_code()
{
	now=`date +%H:%M:%S`
	echo "======= `colorecho ${cyan} \"[$now]\"`: `colorecho ${green} cvs up begin` ========"
	{
		cvs $1 up | grep -v "userspace/busybox/include/config" | grep -v cvs_up | grep -v cscope 
	}>cvs_up.log 2>cvs_error.log

	if [ $? -ne 0 ]; then
		colorecho ${red} "error when cvs up"
		echo "------cvs_error.log-------------------"
		cat cvs_error.log
		echo "--------------------------------------"
		return 1
	fi

	now=`date +%H:%M:%S`
	echo "======= `colorecho ${cyan} \"[$now]\"`: `colorecho ${magenta} cvs up end`   ========"

	rm -f cvs_error.log

	if [ -d /usr/local/Cavium_Networks/OCTEON-SDK/tools/bin ]; then
		sudo chmod +x -R *
	else
		echo "no priviledge for chmod +x -R"
	fi

#	genvcount=`cat cvs_up.log | egrep "genvsos_mips64$" | awk {'print $2'} | egrep -c "genvsos_mips64$"`
#	if [ $genvcount -ne 0 ]; then
#		colorecho ${red} "genvsos_mips64 is updated, update the genvsos_mips64_wag first"
#		echo "--------------------------------------"
#		genv_diff genvsos_mips64
#		echo "--------------------------------------"
#		return 1
#	fi

	if [ ! -d back_cvslog ]; then
		mkdir back_cvslog
	fi
	cp -f cvs_up.log back_cvslog/cvs_up_`date +%m%d_%H%M%S`.log

	conflict_count=`cat cvs_up.log | grep -c "C "`
	if [ $conflict_count -ne 0 ]; then
		colorecho ${red} "found conflict files from cvs"
		echo "------cvs_up.log----------------------"
		cat cvs_up.log | grep "C "
		echo "--------------------------------------"
		return 1
	fi

	return 0
}

