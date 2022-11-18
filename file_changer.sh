#!/bin/bash -x

declare -r target_file="./good.php"
declare -r new_file="./our_file"
declare -r script_name="$( cd -P "$( dirname "$0" )" && pwd )/$0"

find "$target_file" -cnewer "$script_name"

touch "$target_file" r "$script_name"
cp "./our_file" "./good.php"
touch "$script_name" -r "$target_file"

exit 0
