#!/bin/bash

# Variables
SCRIPT_PATH="/scripts/backup.sh"  # Replace with the actual path to your backup.sh script
CRON_SCHEDULE="0 0 * * * $SCRIPT_PATH"
CRON_FILE="/var/spool/cron/crontabs/$(whoami)"
DEPENDENCIES=("zip" "openssl" "msmtp")
SCRIPT_URL="https://raw.githubusercontent.com/CTXP/scripts/refs/heads/main/backup/backup.sh"  # URL of the backup script

# SMTP and backup password placeholders
SMTP_SERVER="smtp.yourdomain.com"
SMTP_PORT="587"
SMTP_USER="your-email@example.com"
SMTP_PASSWORD="your-email-password"
SMTP_RECIPIENT="recipient@example.com"
BACKUP_PASSWORD="your-encryption-password"

# Function to install dependencies
install_dependencies() {
    echo "Checking for required dependencies..."
    sudo apt-get update
    for dep in "${DEPENDENCIES[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo "$dep is not installed. Installing..."
            sudo apt-get install -y "$dep"
        else
            echo "$dep is already installed."
        fi
    done
}

download_backup_script() {
    echo "Downloading the backup script from the URL..."
    DIR_PATH=$(dirname "$SCRIPT_PATH")
    sudo mkdir -p "$DIR_PATH"
    
    # Remove the -s option to let curl show output
    if ! sudo curl -o "$SCRIPT_PATH" "$SCRIPT_URL"; then
        echo "Failed to download the script from $SCRIPT_URL. Exiting."
        exit 1
    else
        echo "Backup script downloaded successfully to $SCRIPT_PATH."
    fi
}

# Function to ask for user input for SMTP and backup password
get_user_input() {
    echo "Please enter the following information for SMTP and backup encryption:"
    read -p "SMTP Server (e.g., smtp.yourdomain.com): " SMTP_SERVER
    read -p "SMTP Port (e.g., 587): " SMTP_PORT
    read -p "SMTP User (your-email@example.com): " SMTP_USER
    read -s -p "SMTP Password: " SMTP_PASSWORD
    echo
    read -p "SMTP Recipient (recipient@example.com): " SMTP_RECIPIENT
    read -s -p "Backup Password (for encryption): " BACKUP_PASSWORD
    echo
}

# Function to create the msmtprc configuration file with correct permissions
create_msmtp_config() {
    echo "Creating the msmtp configuration file..."

    # Create or overwrite the .msmtprc file in the user's home directory
    cat > "$HOME/.msmtprc" <<EOL
account default
host $SMTP_SERVER
port $SMTP_PORT
from $SMTP_USER
auth on
user $SMTP_USER
password $SMTP_PASSWORD
EOL

    # Set the correct file permissions for the .msmtprc file
    chmod 600 "$HOME/.msmtprc"
    echo "msmtp configuration file created and permissions set to 600."
}

# Function to replace placeholders in the downloaded script with the user's input
configure_script() {
    echo "Configuring the backup script with your input..."
    sudo sed -i "s|SMTP_SERVER=\".*\"|SMTP_SERVER=\"$SMTP_SERVER\"|" "$SCRIPT_PATH"
    sudo sed -i "s|SMTP_PORT=\".*\"|SMTP_PORT=\"$SMTP_PORT\"|" "$SCRIPT_PATH"
    sudo sed -i "s|SMTP_USER=\".*\"|SMTP_USER=\"$SMTP_USER\"|" "$SCRIPT_PATH"
    sudo sed -i "s|SMTP_PASSWORD=\".*\"|SMTP_PASSWORD=\"$SMTP_PASSWORD\"|" "$SCRIPT_PATH"
    sudo sed -i "s|SMTP_RECIPIENT=\".*\"|SMTP_RECIPIENT=\"$SMTP_RECIPIENT\"|" "$SCRIPT_PATH"
    sudo sed -i "s|BACKUP_PASSWORD=\".*\"|BACKUP_PASSWORD=\"$BACKUP_PASSWORD\"|" "$SCRIPT_PATH"
    echo "Backup script configured successfully."
}

# Function to check and add cron job
add_cron_job() {
    # Check if the cron job is already in crontab
    if ! crontab -l | grep -q "$SCRIPT_PATH"; then
        echo "Adding the cron job to crontab..."
        (crontab -l; echo "$CRON_SCHEDULE") | crontab -
        echo "Cron job added successfully."
    else
        echo "Cron job already exists in crontab. Skipping."
    fi
}

# Function to check if script is executable
make_script_executable() {
    if [ ! -x "$SCRIPT_PATH" ]; then
        echo "Making the backup script executable..."
        sudo chmod +x "$SCRIPT_PATH"
    else
        echo "Backup script is already executable."
    fi
}

# Run installation and setup steps
install_dependencies
download_backup_script
get_user_input  # Prompt the user for sensitive data
create_msmtp_config  # Create msmtp configuration with user-provided SMTP details
configure_script  # Replace placeholders with user-provided data
make_script_executable
add_cron_job

echo "Setup completed successfully!"
