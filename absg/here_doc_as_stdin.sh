#/bin/bash

function does_output()
{
	ls -al * | awk '{print $5,$9}'
}

nr=0
tot_size=0

while read f_size f_name
do
	echo "${f_name} is ${f_size} butes"
	(( nr++ ))
	(( tot_size+=f_size ))
done <<EOF
$(does_output)
EOF

echo -e "\n${nr} files totaling ${tot_size} bytes\n"

exit 0
