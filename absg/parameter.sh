#!/bin/bash

var1_=$1_
var=$1
echo "var1_ = $var1_ and var = $var"

echo "${*:2}" #echoes second and following parameters
echo "${@:2}" #same as above
echo "${@:2:3}" #echoes three positional parameters, starting at second

echo "${#*}" #print number of positional parameter
echo "${#@}" #same as above
echo "$#" #same as above

for planet in "Mercury 36" "Venus 67" "Earth 93"  "Mars 142" "Jupiter 483"
do
	set -- ${planet}
	echo "$1		${2},000,000 miles from the sun"
done


exit 0
