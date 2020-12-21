#!/bin/bash
########################
# script does not work #
########################

set -x -v

max_tun_num=100
tun_if_num=
root_id=0
remote_ip=
remote_tun_ip=192.168.0.1 local_tun_ip=192.168.0.2
local_router=
default_iface=

function get_router_to_remote()
{
	declare lacal router_ip=$(traceroute --max-hops=1 "${remote_ip}" 2> /dev/null | tail -n 1 | egrep -o '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' || echo "1")
	echo "${router_ip}"
}

function get_inet_iface()
{
	declare local iface=$(ip route show 2> /dev/null | grep default | awk '{print $5}')
	if [[ $iface == "" ]]
	then
		echo "1"
	else
		echo "${iface}"
	fi
}

function valid_ip()
{
	OIFS="${IFS}" IFS='.' ip=($1) IFS="${OIFS}"
	if (( ip[0] > 255 || ip[0] < 1 || ip[1] > 255 || ip[1] < 0 || ip[2] > 255 || ip[2] < 0 || ip[3] > 255 || ip[3] < 0 ))
	then
		return 1
	else
		return 0
	fi
}

function setup_local_connection()
{
	sleep 10
	ip link set dev "tun${2}" up
	ip addr add "${local_tun_ip}/24" dev "tun${2}"
	ip route add "${1}/32" via "${local_router}" dev "${default_iface}"
	ip route del default via "${local_router}" dev "${default_iface}"
	ip route add default via "${remote_tun_ip}" dev "tun${2}"
}

function make_ssh_connection()
{
	ssh "root@${1}" -w "${2}:${2}" << EOF
	sleep 1
	ip link set dev "tun${2}" up
	ip addr add "${remote_tun_ip}/24" dev "tun${2}"
	iptables -t nat -A POSTROUTING -s "${local_tun_ip}" -j SNAT --to-source "${1}"
	echo 1 > /proc/sys/net/ipv4/ip_forward
EOF
}

if [[ $# < 1 ]]
then
	echo "usage $0: remote_ssh_server_ip"
	exit 1
fi

if ! valid_ip $1
then
	echo "ip address $1 is not valid"
	exit 1
fi

if [[ $UID != $root_id ]]
then
	echo "must have root privileges"
	exit 1
fi

RANDOM=$(date +%s)
tun_if_num=$(( "$RANDOM" % "$max_tun_num" ))
remote_ip="${1}"
local_router=$(get_router_to_remote)
default_iface=$(get_inet_iface)
echo "tun iface is: tun${tun_if_num}"
echo "remote ip is: ${remote_ip}"
echo "local router is: ${local_router}"
echo "default iface is: ${default_iface}"
make_ssh_connection "${remote_ip}" "${tun_if_num}" &
setup_local_connection "${remote_ip}" "${tun_if_num}"

exit 0
