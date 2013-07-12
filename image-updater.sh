#!/bin/bash

chck_alive ()
{
	if ping -c 1 -W 3 $1 &>/dev/null ; then
		return 0
	else
		return 1
	fi
}

declare -r image_name=$1
declare -r OIFS=$IFS
declare -r script_name="$0"
declare -r script_dir="$( cd -P "$( dirname "$script_name" )" && pwd )"

[[ -f "/srv/http/img/${image_name}" ]] || echo "file not found /srv/http/img/${image_name}" 

sed -n '/#START_CLIENT_SUBNETS#/,/#END_CLIENT_SUBNETS#/p' /etc/openvpn/server.conf | \
grep -v "CLIENT_SUBNETS" | \
while read -r line ; do
	net_ip=$(echo $line | awk '{print $2}')
	IFS='.' ; ip_arr=($net_ip) ; IFS=$OIFS
	((  ++ip_arr[3] ))
	rout_ip=172.${ip_arr[1]}.${ip_arr[2]}.${ip_arr[3]}
	if chck_alive $rout_ip ; then
		echo -e "router $rout_ip is alive \n\n"
		#scp "/srv/http/img/${image_name}" "root@${rout_ip}:/mnt/rootfs.squashfs"
	else
		echo -e "router $rout_ip is down \n\n"
	fi
done
exit
