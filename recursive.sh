#!/bin/bash

function recursive_do()
{
	for d in *
	do
		if [ -d "$d" ]
		then
			(cd -- "$d" && recursive_do)
		fi	
		#do somthing rm -f *.doc
		#do somthing rm -f *.pdf
	done
}

(cd /tmp && recursive_do)

exit 0
