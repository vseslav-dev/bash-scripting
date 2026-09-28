#!/bin/bash

set -o pipefail

declare -g CHECK_MODE=0 AR NM OUT_FILE IN_FILE TMP_DIR LOG_FILE LIST_INPUT_FILES
declare -g BACKUP_FILE BASE_DIR DEBUG=1 sorted
declare -g NEW_FILE_READY=0
declare -g members

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
	local i="$#"
	printf "\e[33mWarning: \e[0m"
	while (( i > 0 ))
	do
		printf "%s" "$1"
		(( i-- )) && (( i > 0 )) && printf " " && shift
	done
	printf "\n"
}

function err_msg()
{
	local i="$#"
	printf "\e[1;31mError: \e[0m" >&2
	while (( i > 0 ))
	do
		printf "%s" "$1" >&2
		(( i-- )) && (( i > 0 )) && printf " " >&2 && shift
	done
	printf "\n" >&2
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
	local rc="$?"
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
			echo "$IN_FILE" >> "$LOG_FILE"
			rm -f -- "${IN_FILE}.backup" || state=2
			sync
		else
			NEW_FILE_READY=0
			unset OUT_FILE
			state=1
		fi
	fi
	trap interrupted INT TERM HUP
	trap on_exit EXIT
	if (( state == 0 ))
	then
		return "$state"
	elif (( state == 1 ))
	then
		warn_msg "cant mv \"$OUT_FILE\" to \"$IN_FILE\"" \
			"need to replace it manually" \
			"#${LINENO} in ${FUNCNAME[0]}()"
		return "$state"
	elif (( state == 2 ))
	then
		warn_msg "cant remove \"${IN_FILE}.backup\"" \
			"need to remove it manually" \
			"#${LINENO} in ${FUNCNAME[0]}()"
		return "$state"
	elif (( state == 3 ))
	then
		debug_msg \
			"debug mode left undeleted \"$TMP_DIR\" \"$OUT_FILE\"" \
			"and undeleted \"${IN_FILE}.backup\""
		return "$state"
	fi

	return "$state"
}
	
function init()
{
	debug_msg "Lets go..."
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
			err_msg "usage: $0 [--check|-c]"
			return 2
		;;
	esac

	if [ -z "$HOST_DIR" ]
	then
		HOST_DIR="$(pwd)"
	fi

	if [ -z "$BASE_DIR" ]
	then
		BASE_DIR="$(pwd)/output"
		if [ ! -d "$BASE_DIR" ]
		then
			if (( CHECK_MODE == 1 ))
			then
				mkdir -p -- "$BASE_DIR" || { err_msg \
					"cant create ${BASE_DIR} exitting" \
					"#${LINENO} in ${FUNCNAME[0]}()" ; \
					exit 1 ; }
			else
				err_msg "BASE_DIR: \"$BASE_DIR\" does not exist" \
					"#${LINENO} in ${FUNCNAME[0]}()"
				exit 1
			fi
		fi
	fi

	#AR=$(find "${HOST_DIR}/bin" -name '*gnueabi-ar' -print -quit)
	#NM=$(find "${HOST_DIR}/bin" -name '*gnueabi-nm' -print -quit)
	#AR=$(find "${HOST_DIR}/bin" -name 'ar' -print -quit)
	#NM=$(find "${HOST_DIR}/bin" -name 'nm' -print -quit)
	AR="/usr/bin/ar"
	NM="/usr/bin/nm"
	
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

	TMP_DIR=$(mktemp -d "/tmp/ar-normalize.XXXXXXXXXX") || { err_msg \
		"cant create \"tmp dir\" #${LINENO} in ${FUNCNAME[0]}()" ; \
		exit 1 ; }

	LOG_FILE="${BASE_DIR}/lib_repack.log"
	debug_msg "log file is: $LOG_FILE"
	debug_msg "BASE_DIR is: \"$BASE_DIR\""

	if [ -s "$LOG_FILE" ] && [ -f "$LOG_FILE" ]
	then
		debug_msg "log file is not empty and it is ascii file" \
			"#${LINENO} in ${FUNCNAME[0]}()"
		LIST_INPUT_FILES=$(find "${HOST_DIR}" -type f -name '*.a' | \
			grep -F -x -v -f "$LOG_FILE")

	else
		debug_msg "log file was empty or broken" \
			"#${LINENO} in ${FUNCNAME[0]}()"
		LIST_INPUT_FILES=$(find "${HOST_DIR}" -type f -name '*.a' -exec \
			printf "%s\n" {} \; )
		touch "$LOG_FILE"
	fi

	debug_msg "files for modify:" "$LIST_INPUT_FILES" \
		"#${LINENO} in ${FUNCNAME[0]}()"

	trap interrupted INT TERM HUP
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
			err_msg "member name contains '/': $name"
			err_msg "this archive needs a raw archive parser." \
				"#${LINENO} in ${FUNCNAME[0]}()"
			return 1
		fi
		
#		if [[ "$name" == ** || "$name" == *$'\r'* ]]
#		then
#			err_msg "member name contains a newline: $name "
#			err_msg "this archive needs a raw archive parser."
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

		if (( cmp_mode == 1 ))
		then
			cut -f1,2 "$sorted" > "$expected"
			cut -f1,2 "$records" > "$actual"
			if cmp "$expected" "$actual"
			then
				return 0
			else
				return 1
			fi
		fi
		
		rm -rf -- "$exdir"
		
	done < "$members"

	return 0
}

function make_archive() {
	local tmp="$1" out="$2"
	local name hash num add rc
	local records="${tmp}/records"

	# if already exist
	if [ -e "$out" ]
	then
		warn_msg "temporary archive already exists: $out" \
			"#${LINENO} in ${FUNCNAME[0]}()"
		rm -rf -- "$out" || { err_msg "cant delete $out file" ; \
			return 1 ; }
	fi


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
		else
			mkdir -p -- "$add" || { err_msg \
				"cant create $add directory" ; \
				"#${LINENO} in ${FUNCNAME[0]}()" ; \
				return 1 ; }
		fi
		
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
	local state
	local cmp_dir=$(mktemp -d "/tmp/ar-cmp_dir.XXXXXXXXXX") || { err_msg \
		"cant create \"cmp_dir\"" \
		"#${LINENO} in ${FUNCNAME[0]}()" ; exit 1 ; }

	if ! "$AR" t "$1">"$members"
	then
		err_msg "ar cant read archive: \"${1}\"" \
			"#${LINENO} in ${FUNCNAME[0]}()"
	fi

	if extract_src "$1" "$cmp_dir" "1"
	then
		state=0
	else
		err_msg "func: extract_src was returned non zero" \
			"#${LINENO} in ${FUNCNAME[0]}()"
		state=1
	fi

	rm -rf -- "$cmp_dir" || warn_msg "cant remove cmp_dir \"$cmp_dir\"" \
		"#${LINENO} in ${FUNCNAME[0]}()"

	return "$state"
}

	
function cleanup_tmp_dir()
{
	rm -rf -- "${TMP_DIR}"/*
	rm -rf -- "${TMP_DIR}"/.*
}

function main_loop()
{
	local magic rc
	local prev_sort="${TMP_DIR}/prev_sorted_nm"
	local post_sort="${TMP_DIR}/post_sorted_nm"

	while read -r IN_FILE # IN_FILE variable exist libsomelib.a
	do
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
	
		magic=$(head -c 8 -- "$IN_FILE")
	
		case "$magic" in
			'!<arch>'*) # our case
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
					err_msg "backup is not a hard link to input file" \
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
				fi

				OUT_FILE="${IN_FILE}.$(mktemp -u "new.XXXXXXXXXX")"
				debug_msg "new file is ${OUT_FILE}" \
					"#${LINENO} in ${FUNCNAME[0]}()"
	
				if ! "$AR" t "$IN_FILE">"$members"
				then
					err_msg "ar cant read archive:" \
						"\"${IN_FILE}\"" \
						"#${LINENO} in ${FUNCNAME[0]}()"
					cleanup_tmp_dir
					continue
				fi
	
				if ! LC_ALL=C "$NM" "$IN_FILE" 2>/dev/null | \
					LC_ALL=C sort>"$prev_sort"
				then
					err_msg "nm failed for read ${IN_FILE}" \
						"#${LINENO} in ${FUNCNAME[0]}()"
					cleanup_tmp_dir
					continue
				fi
	
				if ! extract_src "$IN_FILE" "$TMP_DIR"
				then
					warn_msg "Cannot extract archive" \
						"\"$IN_FILE\", continue" \
						"#${LINENO} in ${FUNCNAME[0]}()"
					cleanup_tmp_dir
					continue
				fi

				if ! make_archive "$TMP_DIR" "$OUT_FILE"
				then
					warn_msg "Cannot create new archive: " \
						"\"$OUT_FILE\" continue" \
						"#${LINENO} in ${FUNCNAME[0]}()"
					cleanup_tmp_dir
					continue
				fi

				if ! LC_ALL=C "$NM" "$OUT_FILE"| \
					LC_ALL=C sort>"$post_sort"
				then
					err_msg "nm failed to read:" \
						"\"$OUT_FILE\"" \
						"#${LINENO} in ${FUNCNAME[0]}()"
					cleanup_tmp_dir
					continue
				fi

				trap "" EXIT INT TERM HUP

				if cmp "$prev_sort" "$post_sort"
				then
					NEW_FILE_READY=1
					debug_msg "cmp \"$prev_sort\" and" \
						"\"$post_sort\" is equal"
				else
					trap interrupted INT TERM HUP
					trap on_exit EXIT
					warn_msg "cmp \"$prev_sort\" and" \
						"\"$post_sort\" is different"
					cleanup_tmp_dir
					continue
				fi

				replace_lib "$OUT_FILE" "$IN_FILE"
				rc="$?"
				if (( rc == 0 ))
				then
					debug_msg "WIN!!! we replaced this lib"
					cleanup_tmp_dir
					continue
				elif (( rc == 4 ))
				then
					exit 0
				else
					exit 1
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
	done <<< "$LIST_INPUT_FILES"
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

