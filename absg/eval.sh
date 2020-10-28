#!/bin/bash

echo

set -- $(echo one two tree four five)
par=1
params=$#
while (( "$par" <= "$params" ))
do
	echo -n \$$par
	echo -n " = "
	eval "echo \$$par"
	(( par++ ))
done

echo

#eval array elements
declare -a array

array[1]="one; two; three; four;"
array[2]="four; one;"

one() { echo "ONE"; }
two() { echo "TWO"; }
three() { echo "THREE"; }
four() { echo "FOUR"; }

echo -e  "eval array[1]\n"
eval ${array[1]}
echo
echo -e "eval array[2]\n"
eval ${array[2]}


chkMirrorArchs () {
  arch="$1";
  if [ "$(eval "echo \${$(echo get$(echo -ne $arch |
       sed 's/^\(.\).*/\1/g' | tr 'a-z' 'A-Z'; echo $arch |
       sed 's/^.\(.*\)/\1/g')):-false}")" = true ]
  then
     return 0;
  else
     return 1;
  fi;
}

echo -e  "\n\nchkMirrorArchs eval - sed example\n\n"

getSparc="true"
unset getIa64
chkMirrorArchs sparc
echo $?        # 0
               # True

chkMirrorArchs Ia64
echo $?        # 1
               # False
exit 0
