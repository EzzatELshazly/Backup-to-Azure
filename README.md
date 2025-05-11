# Backup-to-Azure

# Daily SQLite Backup to Azure Blob Storage (with AzCopy)

This document outlines the setup and configuration of a daily backup system for a SQLite database file to Azure Blob Storage using AzCopy and cron jobs on a Linux server.

## 1. Script Overview

The script backs up a SQLite file located at `/var/www/frontuat/db.sqlite3` to an Azure Blob container daily at 6 PM Egypt time (3 PM UTC). It uses `azcopy` to transfer the file securely via a SAS URL.

## 2. Prerequisites

- Azure Blob Storage container with a valid SAS token
- `azcopy` installed on the Linux system
- Cron configured to run shell scripts

## 3. Installing azcopy on ubuntu
```bash
wget https://aka.ms/downloadazcopy-v10-linux -O azcopy.tar.gz
tar -xf azcopy.tar.gz
sudo cp ./azcopy_linux_amd64_*/azcopy /usr/local/bin/
azcopy --version
```
### You should see like this:
![Screenshot 2025-05-11 113226](https://github.com/user-attachments/assets/9ecaa930-80c0-4f3d-8263-48cd4cbe0bf9)

## 4. Bash Script

Below is the script saved as `/usr/local/bin/backup_sqlite_to_blob.sh`:

```bash
#!/bin/bash

# Variables
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
```

Make the script executable:
```bash
sudo chmod +x /usr/local/bin/backup_sqlite_to_blob.sh
```

## 4. Cron Job Configuration

Edit the root user's crontab:
```bash
sudo crontab -e
```

Add this line to run the backup daily at 6 PM Egypt time (3 PM UTC):
```cron
0 16 * * * /usr/local/bin/backup_sqlite_to_blob.sh
```

## 5. Logs

Logs are written to `/var/log/backup.log` and include timestamps for start, success, or failure.

![Screenshot 2025-05-11 113912](https://github.com/user-attachments/assets/1f4f3726-bd1c-4a63-9125-ecd4fafd7fa5)


![image](https://github.com/user-attachments/assets/8c9e43f3-233c-4750-b8d6-d244a87c3696)

