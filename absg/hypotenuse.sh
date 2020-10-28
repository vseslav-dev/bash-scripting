#!/bin/bash

args=2
e_badargs=1
success=0

if (( "$#" != "$args" ))
then
	echo "Usage: $(basename $0) leg1 leg2"
	exit $e_badargs
fi

echo -n "hypotenuse of triangle with leg1=$1, and leg2=$2 is: "
echo "scale=7; sqrt("$1" * "$1" + "$2" * "$2")" | bc

exit $success
