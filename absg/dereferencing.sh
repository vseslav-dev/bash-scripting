#!/bin/bash

echo $#
args=$#
echo ${!args}
lastarg=${!args}
echo $lastarg


dereference()
{
	y=\$"$1"
	echo "in function \$y = $y"

	x=$(eval "expr \"$y\" ")
	echo "in function \$1 = \$x: $1 = $x"
	eval "$1=\"some differ text\""
}

junk="some text"
echo "before ivoke function \$junk = $junk"

dereference junk
echo "after invoke function \$junk = $junk"


iter=3
iter_count=1

my_read()
{
	local loc_var

	echo -n "Enter a value: "
	eval 'echo -n "previous value: [$'$1'] "'

	read loc_var
	[ -n "$loc_var" ] && eval $1=\$loc_var
}

while [ "$iter_count" -le "$iter" ]
do
	my_read var
	echo "Entry #$iter_count = $var"
	(( iter_count++ ))
	echo
done

exit 0

