#!/bin/bash

for i in $(find . -name Kconfig)
do
	egrep "depends.*$CONFIG_RAID_MODULE" $i
done
