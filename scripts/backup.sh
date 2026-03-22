#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# OpenClaw Stack — Backup Script
# ============================================================
# Usage:
#   ./scripts/backup.sh                    # Backup to ./backups/
#   ./scripts/backup.sh /mnt/backup        # Custom backup location
#
# Cron example (daily at 3 AM):
#   0 3 * * * /path/to/openclaw-stack/scripts/backup.sh >> /var/log/openclaw-backup.log 2>&1
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKUP_ROOT="${1:-${PROJECT_DIR}/backups}"

DATE=$(date +%Y-%m-%d_%H%M)
BACKUP_DIR="${BACKUP_ROOT}/${DATE}"

log() { echo "[$(date -u +"%Y-%m-%d %H:%M:%S UTC")] $*"; }

log "Starting backup..."
log "Source: ${PROJECT_DIR}/data/"
log "Target: ${BACKUP_DIR}/"

mkdir -p "$BACKUP_DIR"

# Backup workspace and config
rsync -a --delete \
  --exclude='*.log' \
  --exclude='*.tmp' \
  --exclude='node_modules/' \
  "${PROJECT_DIR}/data/" "${BACKUP_DIR}/data/"

# Backup .env (encrypted secrets — handle with care)
if [[ -f "${PROJECT_DIR}/.env" ]]; then
  cp "${PROJECT_DIR}/.env" "${BACKUP_DIR}/.env"
  chmod 600 "${BACKUP_DIR}/.env"
fi

# Backup docker-compose.yml
cp "${PROJECT_DIR}/docker-compose.yml" "${BACKUP_DIR}/"

log "Backup created: ${BACKUP_DIR}"

# Retention: keep last 7 backups
if [[ -d "$BACKUP_ROOT" ]]; then
  BACKUP_COUNT=$(find "$BACKUP_ROOT" -maxdepth 1 -mindepth 1 -type d | wc -l)
  if [[ $BACKUP_COUNT -gt 7 ]]; then
    log "Pruning old backups (keeping 7)..."
    find "$BACKUP_ROOT" -maxdepth 1 -mindepth 1 -type d | sort | head -n -7 | xargs rm -rf
  fi
fi

REMAINING=$(find "$BACKUP_ROOT" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l)
log "Backup complete. ${REMAINING} backup(s) retained."
