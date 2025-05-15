#!/bin/bash

# Simple Backup Script with Cron Support
# This script performs full or partial backups of a directory.
# Supports both interactive mode and command-line argument-based execution for cron jobs.
# Backups are archived and timestamped for organization and logging.

# Configuration
LOG_FILE="$HOME/backup.log"  # Log file to record backup activities.
TIMESTAMP=$(date +%Y%m%d%H%M%S)  # Timestamp for unique backup file names.

# Function to perform the actual backup
perform_backup() {
    # Parameters:
    # $1 - Source directory
    # $2 - Destination directory
    # $3 - Backup type ("full" or "partial")
    # $4 - Extensions (only for partial backups, space-separated)

    local src=$(realpath "$1")
    local dest=$(realpath "$2")
    local type=$3
    local extensions=$4

    # Validate the source directory.
    if [ ! -d "$src" ]; then
        echo "[$(date)] Error: Source directory '$src' not found." | tee -a "$LOG_FILE"
        exit 1
    fi

    # Validate the destination directory.
    if [ ! -d "$dest" ]; then
        echo "[$(date)] Error: Destination directory '$dest' not found." | tee -a "$LOG_FILE"
        exit 1
    fi

    # Perform the backup based on the type specified.
    case "$type" in
        "full")
            # Full backup: Archives all contents of the source directory.
            echo "[$(date)] Starting full backup of $src" >> "$LOG_FILE"
            tar -czf "$dest/backup_full_$TIMESTAMP.tar.gz" -C "$src" .
            echo "[$(date)] Full backup completed: $dest/backup_full_$TIMESTAMP.tar.gz" | tee -a "$LOG_FILE"
            ;;
        "partial")
            # Partial backup: Archives files matching specified extensions.
            if [ -z "$extensions" ]; then
                echo "[$(date)] Error: No extensions provided for partial backup" | tee -a "$LOG_FILE"
                exit 1
            fi
            
            echo "[$(date)] Starting partial backup of $src (extensions: $extensions)" >> "$LOG_FILE"
            
            # Create a temporary file list for matching files.
            filelist=$(mktemp)
            for ext in $extensions; do
                find "$src" -type f -name "*$ext" >> "$filelist"
            done
            
            # Create the backup archive using the file list.
            tar -czf "$dest/backup_partial_$TIMESTAMP.tar.gz" -C "$src" -T "$filelist"
            rm "$filelist"  # Remove the temporary file list.
            
            echo "[$(date)] Partial backup completed: $dest/backup_partial_$TIMESTAMP.tar.gz" | tee -a "$LOG_FILE"
            ;;
        *)
            # Handle invalid backup types.
            echo "[$(date)] Error: Invalid backup type '$type'" | tee -a "$LOG_FILE"
            exit 1
            ;;
    esac
}

# Function for interactive mode
interactive_mode() {
    # Interactive mode guides the user through the backup setup.

    echo "=== Interactive Backup Mode ==="

    # Prompt for source directory.
    read -p "Enter directory to back up: " src
    src=$(realpath "$src")
    while [ ! -d "$src" ]; do
        echo "Error: Directory not found"
        read -p "Enter valid directory to back up: " src
        src=$(realpath "$src")
    done

    # Prompt for destination directory.
    read -p "Enter backup destination: " dest
    dest=$(realpath "$dest")
    while [ ! -d "$dest" ]; do
        echo "Error: Directory not found"
        read -p "Enter valid backup destination: " dest
        dest=$(realpath "$dest")
    done

    # Prompt for backup type.
    echo "Select backup type:"
    echo "1) Full backup"
    echo "2) Partial backup"
    read -p "Enter choice (1-2): " type_choice
    
    case "$type_choice" in
        1)
            backup_type="full"  # Full backup.
            ;;
        2)
            backup_type="partial"  # Partial backup.
            read -p "Enter file extensions to include (space separated, e.g., .txt .jpg): " extensions
            ;;
        *)
            echo "Invalid choice"
            exit 1
            ;;
    esac

    # Perform the backup with the selected options.
    perform_backup "$src" "$dest" "$backup_type" "$extensions"

    # Offer to schedule the backup as a cron job.
    read -p "Schedule this backup? (y/n): " schedule
    if [[ "$schedule" =~ [yY] ]]; then
        echo "Select schedule frequency:"
        echo "1) Daily"
        echo "2) Weekly"
        echo "3) Monthly"
        echo "4) Custom"
        read -p "Enter choice (1-4): " freq
        
        case "$freq" in
            1) cron_time="0 2 * * *" ;;  # Daily at 2 AM.
            2) cron_time="0 2 * * 0" ;;  # Weekly at 2 AM on Sunday.
            3) cron_time="0 2 1 * *" ;;  # Monthly at 2 AM on the 1st.
            4)
                # Allow custom cron schedule.
                echo "Enter cron schedule (min hour day month weekday)"
                echo "Example: '0 2 * * *' for daily at 2AM"
                read -p "Cron schedule: " cron_time
                ;;
            *)
                echo "Invalid choice, not scheduling"
                exit 0
                ;;
        esac
        
        # Add the cron job.
        script_path=$(realpath "$0")
        if [ "$backup_type" == "partial" ]; then
            cron_cmd="$script_path '$src' '$dest' '$backup_type' '$extensions'"
        else
            cron_cmd="$script_path '$src' '$dest' '$backup_type'"
        fi
        
        (crontab -l 2>/dev/null; echo "$cron_time $cron_cmd >> $LOG_FILE 2>&1") | crontab -
        echo "Backup scheduled: $cron_time"
        echo "Command: $cron_cmd"
    fi
}

# Main script execution
if [ $# -ge 3 ]; then
    # Command-line mode for cron jobs.
    perform_backup "$1" "$2" "$3" "$4"
else
    # Interactive mode for user guidance.
    interactive_mode
fi

# Log the completion of the script.
echo "[$(date)] Backup process completed" | tee -a "$LOG_FILE"
