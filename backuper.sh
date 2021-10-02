#!/bin/bash

BACKUP_DIR=/home/ivr/data
WORK_DIR=/home/ivr
DATE=$(date +%Y_%m_%d)

for i in  programming #Downloads Documents Pictures Videos work
do
	tar czvf "${BACKUP_DIR}/${i}_${DATE}.tar.gz" "${WORK_DIR}/${i}"
	if [ $? -ne 0 ]
	then
		echo "error is occurs"
		exit 1
	fi
done

exit 0
