#!/bin/bash

# Default directories
DIRECTORIES_TO_BACKUP="/docker"
BACKUP_DIR="/mnt/backup"
BACKUP_FILE="docker_backup_$(date +\%F).zip"
ENCRYPTED_FILE="${BACKUP_FILE}.enc"
SMTP_SERVER="smtp.yourdomain.com"
SMTP_PORT="587"
SMTP_USER="your-email@example.com"
SMTP_PASSWORD="your-email-password"
SMTP_RECIPIENT="recipient@example.com"
SUBJECT_SUCCESS="Backup Successful"
SUBJECT_FAILURE="Backup Failed"
LOG_FILE="/var/log/backup.log"
BACKUP_PASSWORD="your-encryption-password"

# Additional directories to include (optional, space-separated)
if [ ! -z "$1" ]; then
    DIRECTORIES_TO_BACKUP="$DIRECTORIES_TO_BACKUP $1"
fi

# Logging function
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"  | sudo tee -a "$LOG_FILE" > /dev/null
}

# Send email function with attachment
send_email() {
    SUBJECT=$1
    BODY=$2

    echo -e "Subject:$SUBJECT\n\n$BODY" | msmtp --from="$SMTP_USER" "$SMTP_RECIPIENT"
}

# Backup process
backup() {
    # Create zip file of directories
    sudo touch $LOG_FILE
    log_message "Starting backup of directories: $DIRECTORIES_TO_BACKUP"
    sudo zip -r "$BACKUP_FILE" $DIRECTORIES_TO_BACKUP

    if [ $? -eq 0 ]; then
        log_message "Backup completed successfully."

        # Encrypt the backup
        log_message "Encrypting the backup file"
        sudo openssl enc -aes-256-cbc -in "$BACKUP_FILE" -out "$ENCRYPTED_FILE" -pass pass:"$BACKUP_PASSWORD" -pbkdf2

        if [ $? -eq 0 ]; then
            log_message "Backup encryption successful."
            sudo mv "$ENCRYPTED_FILE" "$BACKUP_DIR"

            # Clean up unencrypted zip
            sudo rm "$BACKUP_FILE"

            # Send success email with log file attached
            send_email "$SUBJECT_SUCCESS" "Backup completed and encrypted successfully. The file is stored at $BACKUP_DIR/$(basename $ENCRYPTED_FILE)" "$LOG_FILE"
        else
            log_message "Encryption failed!"
            send_email "$SUBJECT_FAILURE" "Backup was completed, but encryption failed. Please check the logs." "$LOG_FILE"
        fi
    else
        log_message "Backup failed!"
        send_email "$SUBJECT_FAILURE" "Backup failed. Please check the logs for details." "$LOG_FILE"
    fi
}

# Run the backup
backup