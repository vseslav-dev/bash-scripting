#!/bin/bash

echo -e  "\ngroups of which i am a member\n"
for i in $(seq 0 $(( "${#GROUPS[@]}" - 1 )) ) #${#ARRAY[@]} - number of array members
do
	echo ${GROUPS[$i]} #print the $i member of array
done #prints numbers of groups in which the user is included

echo -e "\nanother way to initialize of array ([0]=null [1]=one etc.\n"
array1=([0]=null [1]=one [2]=two [3]=three)
for i in $(seq 0 $(( "${#array1[@]}" - 1 )) )
do
	echo "element $i of array1 is: ${array1[$i]}"
done


array=( one two three four five five )
replacement()
{
	echo -n "!!!"
}
echo "${array[@]//*/$(replacement)}"


exit 0

