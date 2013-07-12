#!/bin/bash

#program takes an address of the network and checks the speed on the first 20 network addresses.

###########
#functions#

function valid_ip () {
        IFS='.' ; ip=($1) ; IFS=$OIFS
        if (( ip[0] == 172 && ip[1] >= 16 && ip[1] <= 31 && ip[2] >= 0 && ip[2] <= 255 && ( ip[3] == 0 || ip[3] == 128 )  )) ; then
                return 0
        else
                return 1
        fi
}

OIFS=$IFS
NET_IP=$1
US_MES="usage: speed-test 172.16.5.0
valid ip address is 172.16 - 31.0 - 255.0|128"

#validation ip address
if ! valid_ip $NET_IP ; then
	echo "bad ip address $NET_IP"
	echo "$US_MES"
	exit 1;
fi

IFS='.' ; ip=($NET_IP) ; IFS=$OIFS
(( ip[3] += 3 ))
(( host_max = ip[3] + 124 ))
fping -g "${ip[0]}.${ip[1]}.${ip[2]}.${ip[3]}" "${ip[0]}.${ip[1]}.${ip[2]}.$host_max" 2>&1 | grep alive | sed 's/ is alive//g' > /tmp/$$.tmp

for i in $(cat /tmp/$$.tmp | head -n 3) ; do
	echo "testing speed: $i"
	iperf -c $i -p 12458 
	echo ; echo ; echo "############################"
done
exit 0
