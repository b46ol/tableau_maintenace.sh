#!/bin/bash
# Tableau Server Maintenance Script
# Tested on Linux (RHEL / Ubuntu)
# Author: Arif Kurniawan

# =====================================
# Konfigurasi
# =====================================
BACKUP_DIR="/var/opt/tableau/tableau_server/data/tabsvc/files/backups"
LOG_ARCHIVE_DIR="/var/opt/tableau/tableau_server/data/tabsvc/files/log-archive"
DATE=$(date +%F_%H-%M)

DATA_BACKUP_FILE="tableau_backup_${DATE}.tsbak"
LOG_BACKUP_FILE="tableau_logs_${DATE}.zip"

TSM="/opt/tableau/tableau_server/packages/customer-bin.*/tsm"
SCRIPT_LOG="/home/tableau/tableau_maintenance.log"

RETENTION_DAYS=7

echo "======================================" >> "$SCRIPT_LOG"
echo "[$(date)] START weekly Tableau maintenance" >> "$SCRIPT_LOG"

mkdir -p "$BACKUP_DIR"
mkdir -p "$LOG_ARCHIVE_DIR"

# =====================================
# 1. Backup DATA (ONLINE)
# =====================================
echo "[$(date)] Running Tableau DATA backup..." >> "$SCRIPT_LOG"

$TSM maintenance backup \
  -f "$DATA_BACKUP_FILE" >> "$SCRIPT_LOG" 2>&1

if [ $? -ne 0 ]; then
  echo "[$(date)] DATA BACKUP FAILED" >> "$SCRIPT_LOG"
  exit 1
fi

echo "[$(date)] Data backup success: $DATA_BACKUP_FILE" >> "$SCRIPT_LOG"

# =====================================
# 2. Backup LOG (ziplogs)
# =====================================
echo "[$(date)] Running Tableau LOG backup..." >> "$SCRIPT_LOG"

$TSM maintenance ziplogs \
  -f "$LOG_BACKUP_FILE" \
  -o >> "$SCRIPT_LOG" 2>&1

if [ $? -eq 0 ]; then
  echo "[$(date)] Log backup success: $LOG_BACKUP_FILE" >> "$SCRIPT_LOG"

else
  echo "[$(date)] LOG BACKUP FAILED" >> "$SCRIPT_LOG"
fi

# =====================================
# 3. Cleanup LOG & TEMP Tableau
# =====================================
echo "[$(date)] Running Tableau cleanup..." >> "$SCRIPT_LOG"

$TSM maintenance cleanup >> "$SCRIPT_LOG" 2>&1

# =====================================
# 4. Retention cleanup (file system)
# =====================================
echo "[$(date)] Cleaning old backups (> ${RETENTION_DAYS} days)" >> "$SCRIPT_LOG"

find "$BACKUP_DIR" -name "tableau_backup_*.tsbak" -type f -mtime +$RETENTION_DAYS -delete
find "$LOG_ARCHIVE_DIR" -name "tableau_logs_*.zip" -type f -mtime +$RETENTION_DAYS -delete

echo "[$(date)] END weekly Tableau maintenance" >> "$SCRIPT_LOG"