#!/bin/bash

if [[ -z "$1" ]]
then
	file_name="names.data"
else
	file_name="$1"
fi

exec 3<&0
exec 0<"$file_name"

count=0
name=

while echo $name | grep -q -v 'read'
do
	read name
	echo $name
	(( count += 1 ))
done

exec 0<&3
exec 3<&-

echo -e "\nlines in ${file_name} = ${count}\n"

exit 0
