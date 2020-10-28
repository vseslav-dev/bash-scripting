#!/bin/bash

if [[ $# -eq 0 ]]
then
	echo "Usage $0 C-program-file" >&2
	exit 1
fi


WEIRD=$'\377'
[[ $# -eq 1 ]] || usage
case `file "$1"` in
  *"ASCII text"*) sed -e "s%/\*%${WEIRD}%g;s%\*/%${WEIRD}%g" "$1" \
     | tr '\377\n' '\n\377' \
     | sed -ne 'p;n' \
     | tr -d '\n' | tr '\377' '\n';;
  *) echo "Usage $0 C-program-file" >&2 ;;
esac

exit 0
