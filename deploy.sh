#!/bin/bash

#deploy.sh -c $VERSION_NUMBER compiling the programm and create symlink
#deploy.sh -s $FILENAME only create symlink

declare -r BASE_IMGNAME="bingo.tar.gz"
declare -r DATE=$(date +%F)
declare -r SYMLINK="/srv/http/play/bingo.tar.gz"
declare -r SCRIPT_NAME="$0"
##### directories
declare -r BASE_DIR="/home/ivr/work/programming/bash-scripting/deploy"
declare -r RUN_DIR="$( cd -P "$( dirname "$SCRIPT_NAME" )" && pwd )"
declare -r BUILD_DIR="${BASE_DIR}/bingo/src/Binary/Bingo" #without end slash
declare -r IMAGE_DIR="${BASE_DIR}/bingo/builds"


function error_mes()
{
	if [[ $1 == "" ]] ; then
		local MESSAGE="usage: $SCRIPT_NAME -s '${FILENAME}' - to create symlink \n       $SCRIPT_NAME - to compile and create symlink"
	else
		local MESSAGE="bad parameter $1 \nusage: $SCRIPT_NAME -s '${FILENAME}' - to create symlink \n$SCRIPT_NAME - to compile and create symlink"
	fi
	echo -e "$MESSAGE"
	return 0
}

function main()
{
	#command line arguments parsing
	echo "options: $1 $2 $3"

	local OPT_ACTION="$1"
	local OPT_SECOND="$2"
	case "$OPT_ACTION" in
		-s	) create_symlink $OPT_SECOND ;;
		-c	) build_image $OPT_SECOND ;;
		*	) error_mes ; exit 1 ;;
	esac
	exit 0
}


function create_symlink() 
{
	local LINK_TO=$1
	############
	# check play image exist
	if [[ ! -f "$LINK_TO" ]] ; then
		echo "file $LINK_TO not found"
		error_mes $LINK_TO
		exit
	fi

	rm -f "$SYMLINK"
	ln -s "${IMAGE_DIR}/$(basename $LINK_TO)" "$SYMLINK"
	if [[ ! -L "$SYMLINK" ]] ; then
		echo "cannot create symlink"
		exit 1
	else
		ls -l "$SYMLINK"
		echo "create sucesfully"
	fi
	return 0
}


function build_image()
{
	########################
	#check directories exist
	if ! mkdir -p "$BUILD_DIR" "$IMAGE_DIR" ; then
		echo "cannoot create working directories, permission denied"
		exit 1
	fi

	################
	# create file prefix
	local NULL_PREF="$$"
	echo $NULL_PREF
	local PREF=""
	if [[ "$1" == "" ]] ; then
		(( PREF = $NULL_PREF + $(date +%d) + $(date +%H) ))
	else
		local PREF="$1"
	fi
	echo $PREF
	################

	################
	# check file exists
	local FULL_RESULT_FNAME="${IMAGE_DIR}/${PREF}.${DATE}.${BASE_IMGNAME}"
	if [[ -f "$FULL_RESULT_FNAME" ]] ; then
		echo "file $FULL_RESULT_FNAME exist"
		error_mes $FULL_RESULT_FNAME
		exit 1
	fi
	if compile ; then
		echo "compile is ok"
	else
		echo "compile not sucessfull"
		exit 1
	fi

	cd "$BUILD_DIR"
	tar czf "$FULL_RESULT_FNAME" *
	rm -r *
	cd "$RUN_DIR"

	#################
	# create symlink
	create_symlink "$FULL_RESULT_FNAME"

	return 0
}

function compile()
{
# Put here your compile command
# if compile is ok ; then return 0
# if compile is trouble ; then return 1
	touch "${BUILD_DIR}/Bingo.exe" "${BUILD_DIR}/test.mdb" #remove, only for tests
	mkdir -p "${BUILD_DIR}/Resources"


	############
	# check compile
	if [[ -f "${BUILD_DIR}/Bingo.exe" ]] ; then
		return 0
	else
		return 1
	fi
}

#############
# entry point to the program
main $*


