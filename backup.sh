#!/bin/bash

# PostgreSQL Backup Script
# Supports full and incremental backups for PostgreSQL 17

echo "Welcome to PostgreSQL Backup Script!"

# Prompt for database details
read -p "Enter PostgreSQL Host: " PG_HOST
read -p "Enter PostgreSQL Port (default 5432): " PG_PORT
PG_PORT=${PG_PORT:-5432}
read -p "Enter PostgreSQL Username: " PG_USER
read -sp "Enter PostgreSQL Password: " PG_PASS
echo ""
read -p "Enter Database Name: " PG_DB

# Export credentials for the script
export PGPASSWORD=$PG_PASS

# Prompt for backup directory
read -p "Enter the backup directory path: " BACKUP_DIR

# Function for full backup
full_backup() {
    TIMESTAMP=$(date +%Y%m%d%H%M%S)
    FULL_BACKUP_PATH="$BACKUP_DIR/full_backup_$TIMESTAMP"
    
    echo "Performing full backup..."
    mkdir -p "$FULL_BACKUP_PATH"
    
    pg_basebackup -h $PG_HOST -p $PG_PORT -U $PG_USER -D "$FULL_BACKUP_PATH" -Ft -z -P -X stream
    if [ $? -eq 0 ]; then
        echo "Full backup completed and saved to $FULL_BACKUP_PATH"
    else
        echo "Error: Full backup failed."
    fi
}

# Function for incremental backup (WAL Archiving)
incremental_backup() {
    echo "Configuring WAL Archiving for incremental backups..."
    
    # Set up WAL archiving
    WAL_ARCHIVE_DIR="$BACKUP_DIR/wal_archive"
    mkdir -p "$WAL_ARCHIVE_DIR"
    sudo chown postgres:postgres "$WAL_ARCHIVE_DIR"
    sudo chmod 700 "$WAL_ARCHIVE_DIR"
    
    echo "Please configure the following in your postgresql.conf:"
    echo "  wal_level = replica"
    echo "  archive_mode = on"
    echo "  archive_command = 'cp %p $WAL_ARCHIVE_DIR/%f'"
    echo ""
    echo "Restart PostgreSQL after updating the configuration."
    
    echo "Incremental backup using WAL archiving configured. Changes will be stored in $WAL_ARCHIVE_DIR."
}

# Main menu
echo "Choose an option:"
echo "1. Full Backup"
echo "2. Configure Incremental Backup (WAL Archiving)"
read -p "Enter your choice (1/2): " CHOICE

case $CHOICE in
    1)
        full_backup
        ;;
    2)
        incremental_backup
        ;;
    *)
        echo "Invalid option. Exiting."
        ;;
esac

# Cleanup
unset PGPASSWORD
