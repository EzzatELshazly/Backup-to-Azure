# Backup Files from Ubuntu to Azure Blob Storage: A Step-by-Step Guide

This guide explains how to set up a robust system to back up files (e.g., a SQLite database files,photos,logs,important files) from an Ubuntu machine to Azure Blob Storage on a daily, monthly, or custom schedule using **AzCopy** and **cron**. It includes instructions for generating **Shared Access Signature (SAS) tokens** for secure access and an architecture diagram for clarity.

---
## What is AzCopy?

AzCopy is a Command Line utility that provides the capability of migrating the files from local on premises system to Azure storage account and move files in between the storage account such as copying files from a blob to another blob.

## Why This Matters
Automating backups to Azure Blob Storage ensures data durability, scalability, and security. This solution is ideal for managing critical files on Linux servers.

---

## Architecture Overview
The backup process involves copying files from an Ubuntu server to Azure Blob Storage using AzCopy, scheduled via cron jobs. A SAS token secures the transfer without exposing storage account keys.

![image](https://github.com/user-attachments/assets/033aeeb0-3dae-4097-aee4-57ca1ae9082e)


*Diagram*: Ubuntu server → AzCopy → Azure Blob Storage (secured with SAS token).

---

## Prerequisites
- **Azure Blob Storage Account**: Create a storage account and a container (e.g., `backups`).
- **Ubuntu Server**: With internet access and root/sudo privileges.
- **AzCopy**: To transfer files to Azure.
- **Cron**: For scheduling backups.
- **Azure Portal Access**: To generate SAS tokens.

---

## Step 1: Install AzCopy on Ubuntu
AzCopy is a command-line tool for copying files to Azure Blob Storage.

```bash
# Download and extract AzCopy
wget https://aka.ms/downloadazcopy-v10-linux -O azcopy.tar.gz
tar -xf azcopy.tar.gz

# Copy AzCopy to /usr/local/bin
sudo cp ./azcopy_linux_amd64_*/azcopy /usr/local/bin/

# Verify installation
azcopy --version
```

**Expected Output**:
```
azcopy version 10.x.x
```
![image](https://github.com/user-attachments/assets/24be6592-ba7e-4396-b7ae-e981c7096219)

---

## Step 2: Generate a SAS Token
A **Shared Access Signature (SAS) token** provides secure, time-limited access to your Azure Blob Storage container without sharing the account key.

![generate sas token ](https://github.com/user-attachments/assets/698495b0-afd7-461c-befc-cc54cf516756)

### Steps to Create a SAS Token
1. **Log in to the Azure Portal**:
   - Navigate to your storage account.
2. **Select the Container**:
   - Go to the container (e.g., `backups`) under "Data storage" > "Containers".
3. **Generate SAS Token**:
   - Click "Shared access signature" in the storage account menu.
   - Configure permissions:
     - **Allowed services**: Blob
     - **Allowed resource types**: Object
     - **Permissions**: Read, Write, Add, Create, Delete
     - **Start and expiry date**: Set a long expiry (e.g., 2035-05-08) for automation.
     - **Allowed protocols**: HTTPS only
   - Click "Generate SAS and connection string".
4. **Copy the Blob SAS URL**:
   - The URL looks like:
     ```
     https://<account>.blob.core.windows.net/<container>?sp=rawd&st=2025-05-08T15:06:11Z&se=2035-05-08T23:06:11Z&sv=2024-11-04&sr=c&sig=<signature>
     ```
   - Replace `<container>` with your container name (e.g., `backups`) in scripts.

**Security Tip**: Store the SAS token securely (e.g., in an environment variable or a secrets manager) and regenerate it before expiry.

---

## Step 3: Create the Backup Script
This Bash script copies a file (e.g., `/var/www/frontuat/db.sqlite3`) to Azure Blob Storage with a timestamped filename.

Save the script as `/usr/local/bin/backup_to_blob.sh`:

```bash
#!/bin/bash

# Variables
SOURCE_FILE="/var/www/frontuat/db.sqlite3"
BACKUP_NAME="db-$(date +'%Y-%m-%d-%H%M%S').sqlite3"
CONTAINER_URL="https://<account>.blob.core.windows.net/backups/${BACKUP_NAME}?sp=rawd&st=2025-05-08T15:06:11Z&se=2035-05-08T23:06:11Z&sv=2024-11-04&sr=c&sig=<signature>"
LOG_FILE="/var/log/backup.log"

# Ensure log file exists
touch "$LOG_FILE"

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
sudo chmod +x /usr/local/bin/backup_to_blob.sh
```

**Notes**:
- Replace `<account>` and `<signature>` in `CONTAINER_URL` with your SAS URL details.
- Adjust `SOURCE_FILE` to the path of the file you want to back up.

---

## Step 4: Schedule Backups with Cron
Use `cron` to run the backup script on a schedule (e.g., daily at 6 PM Egypt time, which is 3 PM UTC).

1. Edit the root crontab:
   ```bash
   sudo crontab -e
   ```

2. Add a cron job for the desired schedule:
   - **Daily at 6 PM Egypt time (3 PM UTC)**:
     ```
     0 15 * * * /usr/local/bin/backup_to_blob.sh
     ```
   - **Monthly on the 1st at 6 PM Egypt time**:
     ```
     0 15 1 * * /usr/local/bin/backup_to_blob.sh
     ```
   - **Custom schedule**: Use a cron expression (e.g., `0 15 * * 1` for every Monday).

**Cron Syntax**:
```
* * * * *  command
| | | | |
| | | | +---- Day of week (0-7, Sunday=0 or 7)
| | | +------ Month (1-12)
| | +-------- Day of month (1-31)
| +---------- Hour (0-23)
+------------ Minute (0-59)
```

---

## Step 5: Monitor Logs
The script logs backup activity to `/var/log/backup.log`. Check logs to verify success or troubleshoot issues:
```bash
cat /var/log/backup.log
```

**Sample Log**:
```
Backup started at Sun May 11 18:00:00 UTC 2025
Backup SUCCESS at Sun May 11 18:00:05 UTC 2025
```
![Screenshot 2025-05-11 113912](https://github.com/user-attachments/assets/1f4f3726-bd1c-4a63-9125-ecd4fafd7fa5)

---

## Step 6: Test the Backup
Manually run the script to ensure it works:
```bash
sudo /usr/local/bin/backup_to_blob.sh
```

Verify the file appears in your Azure Blob Storage container via the Azure Portal or CLI.

![image](https://github.com/user-attachments/assets/5a3fa8f7-db56-446f-bb30-d31d9e7a8144)

---
## Note: The transfer ( upload ) data take seconds.

## Troubleshooting
- **AzCopy fails**: Verify the SAS token is valid and has Write permissions.
- **Cron not running**: Check `sudo systemctl status cron` and ensure the script is executable.
- **Logs empty**: Ensure `/var/log/backup.log` has write permissions (`sudo chmod 666 /var/log/backup.log`).

---

## Conclusion
This setup provides a reliable, automated backup solution for Ubuntu servers using Azure Blob Storage. Customize the schedule and file paths to suit your needs, and leverage the cloud for secure, scalable storage.
