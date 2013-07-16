#!/bin/bash

quiet=1
for i in $* ; do
	case $i in
		-q) quiet=0;;
		*)  digit=$i;;
	esac
done

if echo $digit | egrep -q '\<0x[[:xdigit:]]+\>' ; then
	if (( $quiet == 1 )) ; then
		echo -ne "hex digit = dec "
	fi
	printf '%d\n' $digit
elif echo $digit | egrep -q '\<[[:digit:]]+\>' ; then
	if (( $quiet == 1 )) ; then
		echo -ne "dec $digit = hex "
	fi
	printf '%x\n' $digit
else
	echo "somfing else"
fi
#printf '%x\n' $1
