#!/bin/bash

# This script is designed to create users and groups, set up home directories, generate passwords, and log actions.
# It creates a new IAM password policies and the necessary permissions and attaches it to the root directory.
#Author: Gideon Adjei

# Configuration
PASSWORD_FILE="/root/user_passwords.txt"
LOG_FILE="$(dirname "$0")/iam_setup.log"
EMAIL_SUBJECT="Your New Linux Account Credentials"
USERS_FILE="$1"

#This function ensures only root can run this script
if [ "$(id -u)" -ne 0 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: This script must be run as root" | tee -a "$LOG_FILE"
    exit 1
fi

# Initialize log file
touch "$LOG_FILE"
chmod 644 "$LOG_FILE"  # Readable by others for auditing
echo "=== USER CREATION LOG - $(date '+%Y-%m-%d %H:%M:%S') ===" >> "$LOG_FILE"

# Initialize password file
touch "$PASSWORD_FILE"
chmod 600 "$PASSWORD_FILE"

# Check for mail command
if ! command -v mail &> /dev/null; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: 'mail' command not found. Install with: sudo apt install mailutils" | tee -a "$LOG_FILE"
    exit 1
fi

# Check if users file exists
if [ ! -f "$USERS_FILE" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Users file $USERS_FILE not found" | tee -a "$LOG_FILE"
    exit 1
fi

# Setting up password complexity check
is_password_complex() {
    local pwd="$1"
    [[ ${#pwd} -ge 8 ]] &&
    [[ "$pwd" =~ [A-Z] ]] &&
    [[ "$pwd" =~ [a-z] ]] &&
    [[ "$pwd" =~ [0-9] ]] &&
    [[ "$pwd" =~ [\@\#\!\%\^\&\*\(\)\_\+\.\,\;\:] ]]
}

# User creation function
create_user_with_email() {
    local username="$1"
    local fullname="$2"
    local group="$3"
    local user_email="$4"

    # Generate password
    while true; do
        temp_password=$(openssl rand -base64 12)
        is_password_complex "$temp_password" && break
    done

    # Check if user exists
    if id "$username" &>/dev/null; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: User $username already exists. Skipping." | tee -a "$LOG_FILE"
        return 1
    fi

    # Create user
    if ! useradd -s /bin/bash -m -d "/home/$username" -c "$fullname" "$username"; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to create user $username" | tee -a "$LOG_FILE"
        return 1
    fi

    # Set password
    if ! echo "$username:$temp_password" | chpasswd; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to set password for $username" | tee -a "$LOG_FILE"
        userdel -r "$username" 2>/dev/null
        return 1
    fi

    # Force password change
    chage -d 0 "$username"

    # Group management
    if ! getent group "$group" >/dev/null; then
        if ! groupadd "$group"; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: Failed to create group $group" | tee -a "$LOG_FILE"
        fi
    fi
    usermod -aG "$group" "$username"

    # Log credentials securely
    echo "$username:$temp_password" >> "$PASSWORD_FILE"

    # Email notification
    local message="Hello $fullname,

Your new Linux account has been created:

Username: $username
Temporary Password: $temp_password
Group: $group

You must change your password at first login.

Regards,
IT Team"

    if echo "$message" | mail -s "$EMAIL_SUBJECT" "$user_email"; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: Created $username. Email sent to $user_email" | tee -a "$LOG_FILE"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: Created $username but failed to send email to $user_email" | tee -a "$LOG_FILE"
    fi
}

# Main execution
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Starting user creation from $USERS_FILE" | tee -a "$LOG_FILE"

tail -n +2 "$USERS_FILE" | while IFS=, read -r username fullname group email; do
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] PROCESSING: Creating $username ($fullname)" | tee -a "$LOG_FILE"
    create_user_with_email "$username" "$fullname" "$group" "$email"
done

echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: User creation completed. Log saved to $LOG_FILE" | tee -a "$LOG_FILE"