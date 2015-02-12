#!/bin/bash -

args=""
while getopts 'o:d:r:q:a:t:f:hs' opt; do
    case $opt in
        d)
            desc=$OPTARG
            ;;
        h)
            ./multi_test -h
            exit 0
            ;;
        *)
            args=${args}"-$opt $OPTARG "
            ;;
    esac
done

echo ${args}
echo ${desc}

~/add_route_2.sh del

~/add_route_2.sh
./test.sh $args -d ${desc}"_1c"
~/add_route_2.sh del

./test.sh $args -d direct

~/add_route_3.sh
./test.sh $args -d ${desc}"_2c"
~/add_route_3.sh del

