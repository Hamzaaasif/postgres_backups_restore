#!/bin/bash

# PostgreSQL Full Backup and WAL Archiving Restore Script
# Restores full database backups and replays WAL files for Point-in-Time Recovery (PITR)

echo "=== PostgreSQL Full and WAL Restore Script ==="

# Prompt for required paths and details
read -p "Enter the PostgreSQL data directory path (e.g., /var/lib/postgresql/17/main): " DATA_DIR
read -p "Enter the full backup file path (e.g., /path/to/full_backup.tar): " FULL_BACKUP_FILE
read -p "Enter the WAL archive directory path (e.g., /path/to/wal_archive): " WAL_ARCHIVE_DIR
read -p "Do you want to restore to a specific point in time? (y/n): " PITR_CHOICE

if [ "$PITR_CHOICE" == "y" ]; then
    read -p "Enter the recovery target time (YYYY-MM-DD HH:MM:SS): " RECOVERY_TARGET_TIME
fi

# Step 1: Stop PostgreSQL
echo "Stopping PostgreSQL service..."
sudo systemctl stop postgresql
if [ $? -ne 0 ]; then
    echo "Error: Failed to stop PostgreSQL. Exiting."
    exit 1
fi

# Step 2: Clean up existing data directory
echo "Cleaning up existing PostgreSQL data directory..."
sudo rm -rf "$DATA_DIR"
if [ $? -ne 0 ]; then
    echo "Error: Failed to clean data directory. Exiting."
    exit 1
fi

# Step 3: Restore the full backup
echo "Restoring full backup from $FULL_BACKUP_FILE to $DATA_DIR..."
sudo tar -xvf "$FULL_BACKUP_FILE" -C "$DATA_DIR"
if [ $? -ne 0 ]; then
    echo "Error: Failed to restore full backup. Exiting."
    exit 1
fi

# Set proper permissions on the data directory
echo "Setting permissions on the data directory..."
sudo chown -R postgres:postgres "$DATA_DIR"
sudo chmod -R 700 "$DATA_DIR"
if [ $? -ne 0 ]; then
    echo "Error: Failed to set permissions on the data directory. Exiting."
    exit 1
fi

# Step 4: Restore WAL files
echo "Copying WAL files from $WAL_ARCHIVE_DIR to $DATA_DIR/pg_wal/..."
sudo mkdir -p "$DATA_DIR/pg_wal"
sudo cp "$WAL_ARCHIVE_DIR"/* "$DATA_DIR/pg_wal/"
if [ $? -ne 0 ]; then
    echo "Error: Failed to copy WAL files. Exiting."
    exit 1
fi

# Step 5: Enable recovery mode
echo "Enabling recovery mode..."
sudo touch "$DATA_DIR/recovery.signal"
if [ $? -ne 0 ]; then
    echo "Error: Failed to enable recovery mode. Exiting."
    exit 1
fi

# Step 6: Configure Point-in-Time Recovery (if applicable)
if [ "$PITR_CHOICE" == "y" ]; then
    echo "Setting recovery target time in postgresql.conf..."
    echo "recovery_target_time = '$RECOVERY_TARGET_TIME'" | sudo tee -a "$DATA_DIR/postgresql.conf" > /dev/null
    if [ $? -ne 0 ]; then
        echo "Error: Failed to set recovery target time. Exiting."
        exit 1
    fi
fi

# Step 7: Start PostgreSQL
echo "Starting PostgreSQL service..."
sudo systemctl start postgresql
if [ $? -ne 0 ]; then
    echo "Error: Failed to start PostgreSQL. Exiting."
    exit 1
fi

# Completion message
echo "Restore operation completed successfully."
if [ "$PITR_CHOICE" == "y" ]; then
    echo "Database restored to the specified point in time: $RECOVERY_TARGET_TIME"
else
    echo "Database restored to the latest consistent state."
fi
