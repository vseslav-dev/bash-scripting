#!/bin/bash


 
# Set up limit below
LIMIT="0.05"
log_file="/home/ivr/overload"
 
 
# -----------------------------------------------------------------
 
# Os Specifc tweaks do not change anything below ;)
OS="$(uname)"
TRUE="1"
if [ "$OS" == "FreeBSD" ]; then
	SEP='load averages:'
elif [ "$OS" == "Linux" ]; then
	SEP='load average:'
fi
 
echo $SEP

while true ; do 
	sleep 5
	# get first 5 min load
	F5M=$(uptime | awk -F "$SEP" '{ print $2 }' | cut -d, -f1 | sed 's/ //g')
	# 10 min
	F10M=$(uptime | awk -F "$SEP" '{ print $2 }' | cut -d, -f2 | sed 's/ //g')
	# 15 min
	F15M=$(uptime | awk -F "$SEP" '{ print $2 }' | cut -d, -f3 | sed 's/ //g')
 
	RESULT=$(echo "$F5M > $LIMIT" | bc ) #echo 1.1 1.66 |awk '{print($1>$2,$1<$2)}'

	if (( RESULT == 1 )) ; then
		echo "================================" >> "$log_file"
		date >> "$log_file"
		echo "================================" >> "$log_file"
		echo "Load average: $F5M, $F10M, $F15M" >> "$log_file"
		echo "================================" >> "$log_file"
		ps aux | egrep -v '.+[[:space:]]+[0-9]+[[:space:]]+0\.0' | tail -n +2|sort -k3 -n -r >> "$log_file"
		echo "================================" >> "$log_file"
		continue
	else 
		continue
	fi
done
