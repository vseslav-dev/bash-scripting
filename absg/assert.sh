#!/bin/bash

function assert()
{
	local PARAM_ERR=1
	local ASSERT_FAIL=2
	local ASSERT_SUCESS=0

	if [[ -z "$2" ]]
	then
		echo "Need more parameters"
		return "$PARAM_ERR"
	fi

	lineno="$2"

	if [[ ! "$1" ]]
	then
		echo "Assertion failed: \"$1\""
		echo "File: \"$0\", line: $lineno"
		return "$ASSERT_FAIL"
	else
		return "$ASSERT_SUCESS"
	fi
}

EXIT_SUCESS=0
EXIT_FAILURE=1

a=5
b=4
cond="$a -lt $b"

assert "$cond" $LINENO

if [[ "$?" -gt "$EXIT_SUCESS" ]]
then
	echo "Assertion success"
	exit "$EXIT_SUCESS"
else
	echo "Assertion failed"
	exit "$EXIT_FAILURE"
fi

