#!/bin/bash -

except_name=''
include_dir=''

function fill_cscope_file()
{
    this_dir=$1
    lname=$2
    find ${this_dir} \( -name "*.c" -o -name "*.h" -o -name "*.cc" -o -name "*.cpp" -o -name "*.hpp" \) -type f | egrep -v "(demo|pclint|backup|\\ut\\|utcode|ut_${except_name})" >>$lname
}

while getopts 'e:i:' opt; do
    case $opt in
        e) except_name=${except_name}'|'$OPTARG;;
        i) 
            include_dir=$OPTARG
            if [ ! -d $include_dir ]; then
                echo include_dir $include_dir does not exist, exit ...
                exit 1
            fi
            ;;
        *) echo "`basename $0` [ -e except_name ] [ -i include_dir ]"; exit 1;;
    esac
done

>cscope.files
fill_cscope_file "." "cscope.files"

if [ "$include_dir" != "" ]; then
    fill_cscope_file ${include_dir} "cscope.files"
fi

#ls /usr/include/*.h | grep -v db >> cscope.files
