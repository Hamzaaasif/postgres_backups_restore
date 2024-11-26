# Step-by-Step Guide to WAL Archiving for Incremental Backups
STEPS
- Configure the postgresql.conf file to enable the backup
- Get the initial full backup
- Enable WAL to get incremental backup
- Setup crons to get the backup automatically

### Configure postgres to enable backups

Open the PostgreSQL configuration file, typically located at `/etc/postgresql/17/main/postgresql.conf` or similar path.

Edit the following parameters in the file:
**postgresql.conf**

```bash
wal_level = replica                             # Enables detailed WAL logging necessary for backups
archive_mode = on                               # Enables WAL archiving
archive_command = 'cp %p /path/to/archive/%f'   # Command to copy each WAL file to an archive directory
max_wal_senders = 3                             # Increases WAL senders (optional but useful for larger setups)

```
**Explanation of Parameters**
- `wal_level = replica` ensures the WAL files contain sufficient information for restoring backups.
- `archive_mode = on` enables the archiving process.
- `archive_command` = specifies where and how to save WAL files. Here, each WAL file is copied to the `/path/to/archive` directory. Replace `/path/to/archive` with the directory where you want to store WAL files. Ensure the specified directory exists and has the necessary permissions.
- `max_wal_senders = 3`  is optional but can improve performance by allowing more WAL files to be processed simultaneously.

### Create the WAL Archive Directory

Create the directory specified in `archive_command`
```bash
mkdir -p /path/to/archive
```

### Add Permission for the directory
Ensure PostgreSQL has the correct permissions to write to this directory:

```bash
chown postgres:postgres /path/to/archive
chmod 700 /path/to/archive
```

### Restart postgres service
Apply changes and restart the postgres service

```bash
sudo systemctl restart postgresql
```

## To Get the initial full backup

To use WAL files for incremental backups, you first need a full backup as the baseline. This is because WAL files only contain changes made after the full backup.

Use `pg_basebackup` to take a full backup
```bash
pg_basebackup -D /path/to/backups -Ft -z -P -X stream
```

**NOTE**
In case of getting error of datbase, login with sudo postgres user, then run the pg_backup command again
```bash
sudo -i -u postgres
```

**Explanation of Parameters**
- `-D /path/to/backups` : Specifies the destination directory for the full backup.
- `-Ft`: Saves the backup in tar format (single compressed file).
- `-z`: Compresses the backup to save storage space.
- `-P`: Displays progress during the backup.
- `-X stream` : Includes WAL files needed for consistency within the full backup.


## Enable WAL Archiving in postgresql.conf

To start using WAL archiving, configure PostgreSQL to archive WAL files. This setup will ensure that each change in the database is recorded in the WAL files, which are archived for incremental backup.


## Automate WAL Archiving for Incremental Changes with cron
After configuring WAL archiving, PostgreSQL will automatically store incremental changes in the WAL files and save them to the archive directory `/path/to/archive`. You can configure this directory to store all WAL files created between full backups, allowing for point-in-time recovery.

Schedule a full backup weekly with pg_basebackup and let WAL archiving capture changes in between.

Example cron job to run a full backup every Sunday at 2 AM:
```bash
0 2 * * 0 pg_basebackup -D /path/to/backups/$(date +\%Y-\%m-\%d) -Ft -z -P -X stream
```

### Edit cron jobs with:
```bash 
crontab -e
```
