#!/bin/bash

select vegetable in "beans" "carrots" "potatoes" "onions" "rutabagas"
do
	echo "Your favorite veggie is ${vegetable}."
	break
done


OPS3="$PS3"
PS3="Choose your favorite vegetable: "
echo
choice_of()
{
	select veg
	do
		echo
		echo "Your favorite veggie is ${REPLY}."
		echo
		break
	done
}

choice_of beans rise carrots radishes rutabaga spinach

exit 0

