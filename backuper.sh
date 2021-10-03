#!/bin/bash

BACKUP_DIR="/home/ivr/data/backup"
WORK_DIR="/home/ivr"
DATE="$(date +%Y_%m_%d)"

if [ ! -d "${BACKUP_DIR}" ]
then
	echo "directory ${BACKUP_DIR} does not exist"
	exit 1
fi

if ! mount | grep -q "${BACKUP_DIR%/backup}"
then
	echo "${BACKUP_DIR%/backup} is not mounted"
	exit 1
fi

for i in  Downloads #Documents # programming Pictures Videos work
do
	if [ ! -d "${WORK_DIR}/${i}" ]
	then
		echo "directory ${WORK_DIR}/${i} does not exist"
		echo "skipping"
		continue
	fi
	echo "archieving ${WORK_DIR}/${i}"
	tar -czf "${BACKUP_DIR}/${i}_${DATE}.tar.gz" "${WORK_DIR}/${i}"
	if [ $? -ne 0 ]
	then
		echo "error is occurs"
		exit 1
	fi
done

exit 0
