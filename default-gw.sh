#!/bin/bash

function change_router {
	
	if [[ $STATE = "down" ]] ; then
		echo -e "\n\n\nstate change $STATE down \n!!!!!!!!!!!!!!!!!!!!!!"
		route -n

		while route -n | grep ^0.0.0.0 | grep -q $SECOND_GW ; do
			route del default gw $SECOND_GW dev $SECOND_INT
		done
		route add default gw $SECOND_GW dev $SECOND_INT metric 0

		while route -n | grep ^0.0.0.0 | grep -q $MAIN_GW ; do
			route del default gw $MAIN_GW dev $MAIN_INT
		done
		route add default gw $MAIN_GW dev $MAIN_INT metric 1
		
		route -n
		echo -e "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\n"

	else
		echo -e "\n\n\nstate change $STATE work\n!!!!!!!!!!!!!!!!!!!!!!!"
		route -n
		while route -n | grep ^0.0.0.0 | grep -q $MAIN_GW ; do
			route del default gw $MAIN_GW dev $MAIN_INT
		done
			route add default gw $MAIN_GW dev $MAIN_INT metric 0

		while route -n | grep ^0.0.0.0 | grep -q $SECOND_GW ; do
			route del default gw $SECOND_GW dev $SECOND_INT
		done
		route add default gw $SECOND_GW dev $SECOND_INT metric 1

		route -n
		echo -e "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\n"
	fi
}

function check_router {
	int=$1
	count=$(echo $CHECK_LIST | awk '{print NF}')
	orig_count=$(echo $CHECK_LIST | awk '{print NF}')
	for i in $CHECK_LIST ; do
		if  ping -I $int -c 1 -W 1 -w 1 -q $i > /dev/null  ; then
			 (( count-- ))
		fi
	done
	if (( count > ( orig_count / 2 ) )) ; then
		return 1 #вернем false, так как ниодин пинг не вернулся
	else
		return 0 #вернем true, так как хотя бы один пинг вернулся
	fi
}

CHECK_LIST="www.ru ya.ru mail.ru google.ru vk.com rambler.ru yahoo.com"

MAIN_INT=eth0 #основной интерфейс
SECOND_INT=wlan0 #вторичный интерфейс
MAIN_GW="10.10.1.1"
SECOND_GW="192.168.2.1"

STATE="work"
OLD_STATE=$STATE

while true ; do
	echo "new iteration start"
	sleep 5

	echo -e "\n!!!!!!!!!!!!!!!!"
	echo $STATE
	echo -e "!!!!!!!!!!!!!!!!\n"


	if check_router $MAIN_INT ; then 
		STATE="work"
	else
		STATE="down"
	fi

	if [[ $STATE = $OLD_STATE ]] ; then
		continue
	else
		change_router
		OLD_STATE=$STATE
	fi	
done
