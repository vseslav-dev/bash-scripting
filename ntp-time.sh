#!/bin/bash

export lim=5

server1='0.ru.pool.ntp.org'
server2='1.ru.pool.ntp.org'
server3='2.ru.pool.ntp.org'
server4='3.ru.pool.ntp.org'

until ntpdate $server1 || ntpdate $server2 || ntpdate $server3 || ntpdate $server4
do
	(( lim = $lim - 1 ))
	if (( $lim == 0 ))
	then
		break
	fi
	sleep 5
done

exit 0

