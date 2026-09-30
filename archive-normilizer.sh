#!/bin/bash

set -o pipefail

declare -g CHECK_MODE=0 AR NM OUT_FILE IN_FILE TMP_DIR LOG_FILE LIST_INPUT_FILES
declare -g BACKUP_FILE BASE_DIR DEBUG=0 sorted LOG_DIR log_input log_output
declare -g NEW_FILE_READY=0 err_log
declare -g members
declare -g prog_name="$0"

function print_msg()
{
	local i="$#"
	printf "\e[0;32m%s: \e[0m" "$prog_name"
	while (( i > 0 ))
	do
		printf "%s" "$1"
		(( i-- )) && (( i > 0 )) && printf " " && shift
	done
	printf "\n"
}

function debug_msg()
{
	if (( DEBUG == 0 ))
	then
		return 0
	fi
	local i="$#"
	printf "\e[0;32mDebug: \e[0m"
	while (( i > 0 ))
	do
		printf "%s" "$1"
		(( i-- )) && (( i > 0 )) && printf " " && shift
	done
	printf "\n"
}

function warn_msg()
{
	{
		local i="$#"
		printf "\e[33mWarning: \e[0m"
		while (( i > 0 ))
		do
			printf "%s" "$1"
			(( i-- )) && (( i > 0 )) && printf " " && shift
		done
		printf "\n"
	} | tee >(sed -E 's/\x1b\[33m//g ; s/\x1b\[0m//g'>> "$err_log") >&2
}

function err_msg()
{
	{
		local i="$#"
		printf "\e[1;31mError: \e[0m"
		while (( i > 0 ))
		do
			printf "%s" "$1"
			(( i-- )) && (( i > 0 )) && printf " " && shift
		done
		printf "\n"
	} | tee >(sed -E 's/\x1b\[1;31m//g ; s/\x1b\[0m//g' >> "$err_log") >&2
}

function on_exit()
{
	local rc="$?"
	trap - EXIT INT TERM HUP
	if [ -d "$TMP_DIR" ] && (( CHECK_MODE != 1 ))
	then
		rm -rf -- "$TMP_DIR"
	fi
	exit "$rc"
}

function interrupted()
{
	local rc="$1"
	trap "" EXIT INT TERM HUP
	if [ -z "$TMP_DIR" ]
	then
		trap - EXIT INT TERM HUP
		exit "$rc"
	else
		rm -rf -- "$TMP_DIR"
	fi

	trap - EXIT INT TERM HUP

	exit "$rc"
}

function replace_lib()
{
	local state=0
	if (( $CHECK_MODE == 1 ))
	then
		state=3
	else
		if mv -f -- "$OUT_FILE" "$IN_FILE"
		then
			NEW_FILE_READY=0
			unset OUT_FILE
			if rm -rf -- "$BACKUP_FILE"
			then
				echo "$IN_FILE" >> "$LOG_FILE"
				sync
			else
				state=2
			fi
		else
			NEW_FILE_READY=0
			unset OUT_FILE
			state=1
		fi
	fi
	trap 'interrupted 130' INT
	trap 'interrupted 143' TERM
	trap 'interrupted 129' HUP
	trap on_exit EXIT
	if (( state == 0 ))
	then
		return "$state"
	elif (( state == 1 ))
	then
		warn_msg "cant mv OUT_FILE to \"$IN_FILE\"" \
			"need to replace it manually" \
			"#${LINENO} in ${FUNCNAME[0]}()"
		return "$state"
	elif (( state == 2 ))
	then
		warn_msg "cant remove \"$BACKUP_FILE\"" \
			"need to remove it manually" \
			"#${LINENO} in ${FUNCNAME[0]}()"
		return "$state"
	elif (( state == 3 ))
	then
		debug_msg \
			"debug mode left undeleted \"$TMP_DIR\" \"$OUT_FILE\"" \
			"and undeleted \"$BACKUP_FILE\""
		return "$state"
	fi

	return "$state"
}
	
function list_input_files()
{
	if [ -s "$LOG_FILE" ] && [ -f "$LOG_FILE" ]
	then

		find "$HOST_DIR" -type f -name '*.a' -print0 |
			grep -z -F -x -v -f "$LOG_FILE"
	else

		touch "$LOG_FILE" || return 1

		find "$HOST_DIR" -type f -name '*.a' -print0
	fi
}

function init()
{
	debug_msg "Lets go..."
	# output/target
	if [ -n "${TARGET_DIR:-}" ] && [ "${1-}" = "$TARGET_DIR" ]
	then
		shift
	fi

	case "${1-}" in
		--check|-c)
			CHECK_MODE=1
		;;
		"")
		;;
		*)
			echo "usage: $0 [--check|-c]" >&2
			return 2
		;;
	esac

	# output/host
	if [ -z "$HOST_DIR" ]
	then
		if (( CHECK_MODE == 1 ))
		then
			HOST_DIR="$(pwd)/output/host"
		else
			echo "\$HOST_DIR is not defined. exitting..." >&2
			exit 1
		fi
	fi

	# root output directory. usual buildroot-year.vers/output
	# can be redifined as "make -O" command"
	if [ -z "$BASE_DIR" ]
	then
		BASE_DIR="$(pwd)/output"
		if [ ! -d "$BASE_DIR" ]
		then
			if (( CHECK_MODE == 1 ))
			then
				mkdir -p -- "$BASE_DIR" || { echo \
					"cant create ${BASE_DIR} exitting" \
					"#${LINENO} in ${FUNCNAME[0]}()" ; \
					exit 1 ; }
			else
				echo "BASE_DIR: \"$BASE_DIR\" does not exist" \
					"#${LINENO} in ${FUNCNAME[0]}()"
				exit 1
			fi
		fi
	fi

	LOG_DIR="${BASE_DIR}/log_dir"
	if [ ! -d "$LOG_DIR" ] 
	then
		mkdir -p -- "$LOG_DIR" || { echo "LOG_DIR does not exist" \
			"and cant create it LOG_DIR is: \"$LOG_DIR\"" ; \
			exit 1 ; }
	fi

	err_log="${LOG_DIR}/error.log"

	AR=$(find "${HOST_DIR}/bin" -name '*gnueabi-ar' -print -quit)
	NM=$(find "${HOST_DIR}/bin" -name '*gnueabi-nm' -print -quit)
	#AR=$(find "${HOST_DIR}/bin" -name 'ar' -print -quit)
	#NM=$(find "${HOST_DIR}/bin" -name 'nm' -print -quit)
	#AR="/usr/bin/ar"
	#NM="/usr/bin/nm"
	
	if [ ! -x "$AR" ]
	then
		err_msg "ar nor found"
		exit 1
	else
		debug_msg "ar is: \"$AR\""
	fi
	
	if [ ! -x "$NM" ]
	then
		err_msg "nm not found"
		exit 1
	else
		debug_msg "nm is: \"$NM\""
	fi

	log_input=$(mktemp -d "${LOG_DIR}/input.XXXXXXXXXX") || exit 1
	log_output=$(mktemp -d "${LOG_DIR}/output.XXXXXXXXXX") || exit 1

	TMP_DIR=$(mktemp -d "/tmp/ar-normalize.XXXXXXXXXX") || { err_msg \
		"cant create \"tmp dir\" #${LINENO} in ${FUNCNAME[0]}()" ; \
		exit 1 ; }

	LOG_FILE="${LOG_DIR}/lib_repack.log"
	print_msg "log file is: $LOG_FILE"
	debug_msg "BASE_DIR is: \"$BASE_DIR\""

	debug_msg "files to edit is: $(list_input_files | tr '\000' ' ')"

	trap 'interrupted 130' INT
	trap 'interrupted 143' TERM
	trap 'interrupted 129' HUP
	trap on_exit EXIT
	return 0
}

function extract_src() {
	local src="$1" tmp="$2" cmp_mode="${3:-0}"
	local data exdir f hash num name
	local records="${tmp}/records"
	local expected="${tmp}/expected" actual="${tmp}/actual"
	declare -A obj_repeat_cnt=()

	
	while IFS= read -r name; do
		if [ ! -n "$name" ]
		then
			warn_msg "name $name of object is empty" \
				"#${LINENO} in ${FUNCNAME[0]}()"
			continue
		fi
		
		if [[ "$name" == */* ]]
		then
			err_msg "member name contains '/': $name" \
				"this archive needs a raw archive parser." \
				"#${LINENO} in ${FUNCNAME[0]}()"
			return 1
		fi
		
		if [[ "$name" == *$'\t'* ]]
		then
			err_msg "TAB in member name is not supported: $name" \
				"#${LINENO} in ${FUNCNAME[0]}()"
			return 1
		fi

#		if [[ "$name" == *$'\r'* ]]
#		then
#			err_msg "member name contains a newline: $name " \
#				"this archive needs a raw archive parser." \
#				"#${LINENO} in ${FUNCNAME[0]}()"
#			return 1
#		fi
		
		if [ -n "${obj_repeat_cnt["$name"]}" ]
		then
			(( obj_repeat_cnt["$name"]++ ))
			num=$(( obj_repeat_cnt["$name"] ))
			debug_msg \
				"!!!mul objects: $name appears $num in ${src}" \
				"#${LINENO} in ${FUNCNAME[0]}()"
		else
			(( obj_repeat_cnt["$name"] = 1 ))
			num=1
		fi
		
		exdir="${tmp}/${name}_x.${num}"
		debug_msg "extract dir is: ${exdir} #${LINENO} in ${FUNCNAME[0]}()"
		mkdir -p -- "$exdir" || { err_msg "mkdir $exdir" \
		       "#${LINENO} in ${FUNCNAME[0]}()" ; return 1 ; }
		
		pushd -- "$exdir" > /dev/null || return 1
			"$AR" xN "$num" "$src" "$name" || \
				{ popd > /dev/null ; return 1 ; }

			f=$(find ./ -type f -print -quit)
			if [ -z "$f" ]
			then
				err_msg "failed to extract member: ${name}" \
					"#${LINENO} in ${FUNCNAME[0]}()"
				popd > /dev/null
				return 1
			fi
		
			data="${tmp}/${name}_d.${num}"
		
			mv -- "$f" "$data" || { popd > /dev/null ; \
				err_msg "mv $f to ${data}" \
				"#${LINENO} in ${FUNCNAME[0]}()"; return 1 ; }

		popd > /dev/null || { err_msg "popd" ; return 1 ; }
		
		hash=$(sha256sum -- "$data" | awk '{print $1}') || \
			{ err_msg "hash" ; return 1 ; }
		
		# Fields:
		#   1 = member name
		#   2 = SHA-256 of member contents
		#   3 = unique internal record number
		#

		debug_msg "records file is: \"$records\"" \
			"#${LINENO} in ${FUNCNAME[0]}()"
		printf '%s\t%s\t%s\n' "$name" "$hash" "$num" >> "$records"
		
		rm -rf -- "$exdir"
		
	done < "$members"

	if (( cmp_mode == 0 ))
	then
		cp -- "$records" "${log_input}/$(basename ${src}).records_lst" || \
			{ err_msg "cant cp \"${records}\" to \"${log_input}\"" \
				"#${LINENO} in ${FUNCNAME[0]}()" ; \
				exit 1 ; }
		sync
	fi

	if (( cmp_mode == 1 ))
	then
		cut -f1,2 "$sorted" > "$expected"
		cut -f1,2 "$records" > "$actual"
		if cmp "$expected" "$actual"
		then
			cp -- "$records" \
				"${log_output}/$(basename ${src}).records_lst" || \
				{ err_msg "cant cp \"${records}\"" \
					"#${LINENO} in ${FUNCNAME[0]}()" ; \
					"to \"${log_input}\"" ; exit 1 ; }
			sync
			return 0
		else
			return 1
		fi
	fi

	return 0
}

function make_archive() {
	local tmp="$1" out="$2"
	local name hash num add rc
	local records="${tmp}/records"

	if ! LC_ALL=C sort -t $'\t' -k1,1 -k2,2 -k3,3n "$records" > "$sorted"
	then
		err_msg "cant sort records #${LINENO} in ${FUNCNAME[0]}()"
		return 1
	fi
	
	while IFS=$'\t' read -r name hash num; do
	
		add="${tmp}/${name}_dir${num}"
		
		if [ -e "${add}" ]
		then
			warn_msg "!!!!!! directory $add already exists" \
				"#${LINENO} in ${FUNCNAME[0]}()"
			rm -rf -- "$add" || { err_msg \
				"cant delete $add directory" \
				"#${LINENO} in ${FUNCNAME[0]}()" ; return 1 ; }
		fi

		mkdir -p -- "$add" || { err_msg \
			"cant create $add directory" ; \
			"#${LINENO} in ${FUNCNAME[0]}()" ; \
			return 1 ; }
		
		cp -- "${tmp}/${name}_d.${num}" "${add}/" || { err_msg \
			"cant cp ${tmp}/${name}_d.${num} to ${add}/" \
			"#${LINENO} in ${FUNCNAME[0]}()" ; \
			return 1 ; }
		
		pushd -- "$add" > /dev/null || return 1
	
			mv "./${name}_d.${num}" "./${name}" || { popd ; err_msg \
				"cant mv ./${name}_d.${num} ./${name}" \
				"#${LINENO} in ${FUNCNAME[0]}()" ; \
				return 1 ; }
			"$AR" qD "$out" "$name" || { popd ; err_msg \
				"failed to add member $name to ${out}" \
				"#${LINENO} in ${FUNCNAME[0]}()" ; \
				return 1 ; }
	
		popd > /dev/null || return 1
			
		rm -rf -- "$add"
		
		done < "$sorted"
		
	"$AR" sD "$out" || { err_msg \
		"cant create symbol table and determinate $out file" \
		"#${LINENO} in ${FUNCNAME[0]}()" ; \
		return 1 ; }
		
	if ! "$AR" t "$out" >/dev/null
	then
		err_msg "!!!!! rebuilt archive $out is corrupted" \
			"#${LINENO} in ${FUNCNAME[0]}()"
		return 1
	fi
	
	return 0
}

function check_new_hash()
{
	local state=0 cmp_dir
	cmp_dir=$(mktemp -d "/tmp/ar-cmp_dir.XXXXXXXXXX") || { err_msg \
		"cant create \"cmp_dir\"" \
		"#${LINENO} in ${FUNCNAME[0]}()" ; exit 1 ; }

	if ! "$AR" t "$1">"$members"
	then
		err_msg "ar cant read archive: \"${1}\"" \
			"#${LINENO} in ${FUNCNAME[0]}()"
		rm -rf -- "$cmp_dir" || warn_msg \
			"cant remove cmp_dir \"$cmp_dir\""
		return 1
	fi

	debug_msg "in check_new_hash function" \
		"members of \"$1\" is:" "$(cat $members)" \
		"#${LINENO} in ${FUNCNAME[0]}()"

	if extract_src "$1" "$cmp_dir" "1"
	then
		state=0
		print_msg "check_new_hash is successed. WIN!!!" \
			"#${LINENO} in ${FUNCNAME[0]}()"
	else
		state=1
		err_msg "func: extract_src was returned non zero" \
			"#${LINENO} in ${FUNCNAME[0]}()"
	fi

	rm -rf -- "$cmp_dir" || warn_msg "cant remove cmp_dir \"$cmp_dir\"" \
		"#${LINENO} in ${FUNCNAME[0]}()"

	return "$state"
}
	
function cleanup_tmp_dir()
{
	if [ -z "$TMP_DIR" ] || [ ! -d "$TMP_DIR" ]
	then
		return 1
	fi
	rm -rf -- "${TMP_DIR}"/*
	rm -rf -- "${TMP_DIR}"/.*
}

function main_loop()
{
	local magic rc in_func_fl=0
	local prev_sort="${TMP_DIR}/prev_sorted_nm"
	local post_sort="${TMP_DIR}/post_sorted_nm"

	while IFS= read -r -d '' IN_FILE # IN_FILE variable exist libsomelib.a
	do
		if (( in_func_fl == 1 )) && (( CHECK_MODE == 1 ))
		then
			debug_msg "check mode enable, exitting..." \
				"#${LINENO} in ${FUNCNAME[0]}()"
			exit 0
		fi

		if [ ! -e "$IN_FILE" ]
		then
			warn_msg "file: $IN_FILE does not exist" \
				"#${LINENO} in ${FUNCNAME[0]}()"
			continue
		fi
	
		debug_msg "!!!!!${IN_FILE}!!!!!" \
			"#${LINENO} in ${FUNCNAME[0]}()"
	
		if ! IN_FILE=$(readlink -f -- "$IN_FILE")
		then
			warn_msg "$IN_FILE is bad link" \
				"#${LINENO} in ${FUNCNAME[0]}()"
			continue
		fi
		# file named $IN_FILE exist 

		sorted="${TMP_DIR}/sorted"
		members="${TMP_DIR}/members"
	
		print_msg "processing with $IN_FILE"
		magic=$(head -c 8 -- "$IN_FILE")
	
		case "$magic" in
			'!<arch>'*) # our case
				in_func_fl=1
				BACKUP_FILE="${IN_FILE}.backup"
				if [ -e "$BACKUP_FILE" ] || [ -L "$BACKUP_FILE" ]
				then
					err_msg "backup already exists:" \
						"$BACKUP_FILE" \
						"#${LINENO} in ${FUNCNAME[0]}()"
					return 1
				fi

				if ! ln -- "$IN_FILE" "$BACKUP_FILE"
				then
					err_msg "cant create backup:" \
						"$BACKUP_FILE" \
						"#${LINENO} in ${FUNCNAME[0]}()"
					return 1
				fi
				if [[ ! "$IN_FILE" -ef "$BACKUP_FILE" ]]
				then
					err_msg "backup is not a hard link" \
						"to input file" \
						"#${LINENO} in ${FUNCNAME[0]}()"
					return 1
				fi

				if [ -e "$OUT_FILE" ]
				# it can be: if we try to work with the
				# same file as early
				then
					warn_msg "The prev OUT_FILE $OUT_FILE" \
				       	"was not deleted." \
					"It need to delete manually" \
					"#${LINENO} in ${FUNCNAME[0]}()"
					return 1
				fi

				OUT_FILE="$(mktemp "${IN_FILE}.new.XXXXXXXXXX")" || \
					{ err_msg "cant generate new name" \
						"for OUT_FILE, exitting..." \
						"#${LINENO} in ${FUNCNAME[0]}()" ; \
						return 1 ; }
				debug_msg "new file is ${OUT_FILE}" \
					"#${LINENO} in ${FUNCNAME[0]}()"
	
				chmod --reference="$IN_FILE" "$OUT_FILE" || \
					{ err_msg "canr change file permisiion" \
						"on file \"$OUT_FILE\"" \
						"exitting..."
						"#${LINENO} in ${FUNCNAME[0]}()" ; \
						return 1 ; }

				printf '!<arch>\n' > "$OUT_FILE" || \
					{ err_msg "cant write to OUT_FILE" \
						"${OUT_FILE} exitting..." \
						"#${LINENO} in ${FUNCNAME[0]}()" ; \
						return 1 ; }
				if ! "$AR" t "$IN_FILE">"$members"
				then
					err_msg "ar cant read archive:" \
						"\"${IN_FILE}\"" \
						"#${LINENO} in ${FUNCNAME[0]}()"
					return 1
				fi

				debug_msg "members of \"$IN_FILE\" is" \
					"$(cat $members)" \
					"#${LINENO} in ${FUNCNAME[0]}()"
	
				if ! LC_ALL=C "$NM" "$IN_FILE" 2>/dev/null | \
					LC_ALL=C sort>"$prev_sort"
				then
					err_msg "nm failed for read ${IN_FILE}" \
						"#${LINENO} in ${FUNCNAME[0]}()"
					return 1
				fi
	
				if ! extract_src "$IN_FILE" "$TMP_DIR"
				then
					warn_msg "Cannot extract archive" \
						"\"$IN_FILE\"" \
						"#${LINENO} in ${FUNCNAME[0]}()"
					return 1
				fi

				if ! make_archive "$TMP_DIR" "$OUT_FILE"
				then
					warn_msg "Cannot create new archive: " \
						"\"$OUT_FILE\"" \
						"#${LINENO} in ${FUNCNAME[0]}()"
					return 1
				fi

				if ! LC_ALL=C "$NM" "$OUT_FILE"| \
					LC_ALL=C sort>"$post_sort"
				then
					err_msg "nm failed to read:" \
						"\"$OUT_FILE\"" \
						"#${LINENO} in ${FUNCNAME[0]}()"
					return 1
				fi

				print_msg "replace $OUT_FILE to $IN_FILE"

				trap "" EXIT INT TERM HUP

				if cmp "$prev_sort" "$post_sort"
				then
					if check_new_hash "$OUT_FILE"
					then
						NEW_FILE_READY=1
						debug_msg "All checks have been successfully"
					else
						err_msg "hash sums was not equal"
						trap 'interrupted 130' INT
						trap 'interrupted 143' TERM
						trap 'interrupted 129' HUP
						trap on_exit EXIT
						return 1
					fi
				else
					trap 'interrupted 130' INT
					trap 'interrupted 143' TERM
					trap 'interrupted 129' HUP
					trap on_exit EXIT
					warn_msg "cmp \"$prev_sort\" and" \
						"\"$post_sort\" is different"
					return 1
				fi

				replace_lib "$OUT_FILE" "$IN_FILE"
				rc="$?"
				if (( rc == 0 ))
				then
					print_msg "WIN!!! we replaced this lib"
					cleanup_tmp_dir
					continue
				elif (( rc == 3 ))
				then
					exit 0
				else
					return 1
				fi
			;;
	
			'!<thin>'*)
				debug_msg "\"$IN_FILE\" is thin archive"
				continue
			;;
	
			$'\x7fELF'*)
				debug_msg "\"$IN_FILE\" is ELF file, skiping"
				continue
			;;
	
			*)
				debug_msg "\"$IN_FILE\" format is not recognized"
				continue
			;;
		esac
	done < <(list_input_files)
	return 0
}

if ! init "$@"
then
	err_msg "init() return non succesful code"
	exit 1
fi

if ! main_loop
then
	err_msg "main_loop() return non succesful code"
	exit 1
fi

trap - EXIT INT TERM HUP

rm -rf -- "$TMP_DIR"

exit 0

