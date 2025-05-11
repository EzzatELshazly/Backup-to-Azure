SOURCE_FILE="/var/www/frontuat/db.sqlite3"
BACKUP_NAME="db-$(date +'%Y-%m-%d-%H%M%S').sqlite3"
CONTAINER_URL="https://XXXXXXX.blob.core.windows.net/#blob-name/${BACKUP_NAME}?sp=rawd&st=2025-05-08T15:06:11Z&se=2035-05-08T23:06:11Z&sv=2024-11-04&sr=c&sig=ck98IBGQl2w0n9wHAC9dCyejncDYL1kldSD9An%2BNT3U%3D"
LOG_FILE="/var/log/backup.log"

# Log start
echo "Backup started at $(date)" >> "$LOG_FILE"

# Upload to Azure Blob
azcopy copy "$SOURCE_FILE" "$CONTAINER_URL" >> "$LOG_FILE" 2>&1

# Log result
if [ $? -eq 0 ]; then
    echo "Backup SUCCESS at $(date)" >> "$LOG_FILE"
else
    echo "Backup FAILED at $(date)" >> "$LOG_FILE"
fi
