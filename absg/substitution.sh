#!/bin/bash

capitalizer_first_char ()
{
	str1="$@"
	first=${str1:0:1}
	str2=${str1:1}

	first_char="$(echo "${first}" | tr a-z A-Z)"
	echo "${first_char}${str2}"
}



