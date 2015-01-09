#!/bin/bash -

. tools.sh

function clear_tag_files()
{
    time_echo "rm cscope and tag files"
    find . -name "cscope*" -type f -exec rm -f {} \;
    find . -name "cppcomplete.tags" -type f -exec rm -f {} \;
    find . -name "tags" -type f -exec rm -f {} \;
    find . -name "udtags" -type f -exec rm -f {} \;
}

except_name="-e squid -e aie_icap_module/include/c_icap"
include_dir=""
while getopts 'e:i:hc' opt; do
    case $opt in
        e) except_name=${except_name}" -e $OPTARG";;
        i) 
            if [ ! -d $OPTARG ]; then
                echo include_dir $OPTARG does not exist, exit ...
                exit 1
            fi
            include_dir=" -i "$OPTARG
            ;;
        c)  clear_tag_files; exit 0;;
        h|*) echo "`basename $0` [ -e except_name ] [ -i include_dir ]"; exit 1;;
    esac
done

clear_tag_files

execute_hint vcollect_files.sh ${except_name}$include_dir
execute_hint ctags -I __THROW -R --c++-kinds=+p --fields=+liaS --extra=+q -L cscope.files
cp -af tags cppcomplete.tags 2>/dev/null
execute_hint cscope -Rbq
execute_hint parse_tags.py

echo -n [`date +%H:%M:%S`]
colorecho "green" " [done]"
