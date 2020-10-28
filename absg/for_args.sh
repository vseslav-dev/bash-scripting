#!/bin/bash

if [[ ! -n "$1" ]]
then
	echo "Usage: $0 arg1 arg2 etc."
	exit 1
fi

echo "Listing args with \"$*\""

cnt=1
for i in "$@"
do
	echo "\"Arg${cnt}\" is \"${i}\""
	(( cnt++ ))
done

exit 0
