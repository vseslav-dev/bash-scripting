#!/bin/bash

trap 'echo "VARIABLE-TRACE> \$var = \"$var\""' DEBUG

var=29; line=$LINENO

echo "  Just initialized \$var to $var in line number $line."

(( var *= 3 )); line=$LINENO

echo "  Just multiplied \$var by 3 in line number $line."


trap 'echo vars listing a = $a b = $b' EXIT

a=39; b=36

trap 'echo "cnt+c disabled."' 2

sleep 5

exit 0

