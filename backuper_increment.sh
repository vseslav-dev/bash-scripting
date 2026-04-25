#!/bin/bash

SOURCE_DIR="/home/ivr"
BACKUP_ROOT="/home/ivr/data/backup"
DATE="$(date +%Y_%m_%d)"
LATEST_LINK="${BACKUP_ROOT}/latest"
CURRENT_BACKUP="${BACKUP_ROOT}/${DATE}"

TARGETS=(Desktop Downloads Documents programming Pictures Videos work .local/bin)

if ! mount | grep -q "${BACKUP_ROOT%/backup}"; then
    echo "Disk for ${BACKUP_ROOT} is not mounted!"
    exit 1
fi

mkdir -p "${BACKUP_ROOT}"

echo "Starting incremental backup to ${CURRENT_BACKUP}..."

for item in "${TARGETS[@]}"; do
    if [ ! -d "${SOURCE_DIR}/${item}" ]; then
        echo "Directory ${item} not found, skipping..."
        continue
    fi

    echo -e "--- Processing: ${item} ---\n\n\n"
    
    rsync -ah --info=progress2 --delete \
          --link-dest="${LATEST_LINK}" \
          "${SOURCE_DIR}/${item}/" \
          "${CURRENT_BACKUP}/${item}/"

    if [ $? -ne 0 ]; then
        echo "Error occured during syncing ${item}"
        exit 1
    fi
done

rm -rf "${LATEST_LINK}"
ln -s "${CURRENT_BACKUP}" "${LATEST_LINK}"

echo "Backup finished successfully!"
exit 0

