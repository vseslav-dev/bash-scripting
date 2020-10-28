#!/bin/bash

for outer in $(seq 1 5)
do
	echo  "outer = $outer"
	for inner in $(seq 1 5)
	do
		echo "inner = $inner"
		if [[ "$inner" = 3 ]]
		then
			break 2
		fi
	done
	echo "outer"
done


while true
do
	echo -n "press any key: "
	read key
	case "$key" in
		X)	echo "you pressed the X key. Program will be terminated"
			break
			;;
		[[:lower:]]) echo "lower key"
			;;
		[[:upper:]]) echo "upper key"
			;;
		[0-9]*)	echo "digit"
			;;
		*)	echo "other key"
			;;
	esac
done

exit 0
