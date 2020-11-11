#!/bin/bash

BLUE=( $(ps aux | grep blue | grep -v grep | awk '{print $2}') )
echo "\$BLUE is: ${BLUE[@]}"
renice -n -20 "${BLUE[@]}"

PULSE=( $(ps aux | grep pulse | grep -v grep | awk '{print $2}') )
echo "\$PULSE is: ${PULSE[@]}"
renice -n -20 "${PULSE[@]}"

exit 0

