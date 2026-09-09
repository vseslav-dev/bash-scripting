#!/bin/bash

set -x

if [ "$#" -ne 1 ] ; then
	echo "Usage: $0 \"machine-name\""
	exit 1
fi

BIN_VBOX_MANAGE=$(command -v VBoxManage)

if [ -z "$BIN_VBOX_MANAGE" ] ; then
	echo "Binary VBoxManage is not found"
	exit 1
fi

BIN_CPUID=$(command -v cpuid)

if [ -z "$BIN_CPUID" ] ; then
	echo "Binary cpuid is not found"
	exit 1
fi

MACHINE_NAME=$1
echo "Machine Name is: \"$MACHINE_NAME\""

if ! "$BIN_VBOX_MANAGE" showvminfo "$MACHINE_NAME" >/dev/null 2>&1 ; then
	echo "Machine \"$MACHINE_NAME\" not found"
	exit 1
fi

CPUID_EAX=$(
	"$BIN_CPUID" -r -l 0 |
	sed -n 's/.*eax=\(0x[0-9a-fA-F]\+\).*/\1/p' |
	head -n1
)

if [ -z "$CPUID_EAX" ] ; then
	echo "Cannot get EAX from CPUID leaf 0"
	exit 1
fi

CPUID_EAX=${CPUID_EAX#0x}

echo "CPUID leaf 0 EAX: 0x$CPUID_EAX"

"$BIN_VBOX_MANAGE" modifyvm "$MACHINE_NAME" --cpu-profile host

"$BIN_VBOX_MANAGE" modifyvm "$MACHINE_NAME" \
	--cpuidset 00000000 "$CPUID_EAX" 756e6547 6c65746e 49656e69

"$BIN_VBOX_MANAGE" modifyvm "$MACHINE_NAME" \
	--cpuidset 80000002 20202020 20202020 65746e49 2952286c

"$BIN_VBOX_MANAGE" modifyvm "$MACHINE_NAME" \
	--cpuidset 80000003 726f4320 4d542865 35692029 3734332d

"$BIN_VBOX_MANAGE" modifyvm "$MACHINE_NAME" \
	--cpuidset 80000004 50432030 20402055 30322e33 007a4847

exit 0
