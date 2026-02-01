#!/bin/bash
set -euo pipefail

# =============================================================================
# MySQL Backup Script for Kubernetes
# Backs up MySQL databases and uploads to MinIO object storage
# =============================================================================

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# =============================================================================
# Environment Variables
# =============================================================================
DB_USER=${DB_USER:-${MYSQL_ENV_DB_USER:-}}
DB_PASS=${DB_PASS:-${MYSQL_ENV_DB_PASS:-}}
DB_NAME=${DB_NAME:-${MYSQL_ENV_DB_NAME:-}}
DB_HOST=${DB_HOST:-${MYSQL_ENV_DB_HOST:-}}
DB_PORT=${DB_PORT:-3306}
ALL_DATABASES=${ALL_DATABASES:-}
IGNORE_DATABASE=${IGNORE_DATABASE:-}
NAME_SPACE=${NAME_SPACE:-${MYSQL_ENV_NAME_SPACE:-default}}
BACKUP_RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-7}
MINIO_API_VERSION=${MINIO_API_VERSION:-S3v4}

# Timestamp for backup file
FILE_DATE=$(date +%Y%m%d%H%M%S)
BACKUP_DIR="/mysqldump"
BACKUP_FILE="mysqldump-${FILE_DATE}.tar.gz"

# =============================================================================
# Validation
# =============================================================================
validate_env() {
    local missing=()

    [[ -z "${DB_USER}" ]] && missing+=("DB_USER")
    [[ -z "${DB_PASS}" ]] && missing+=("DB_PASS")
    [[ -z "${DB_HOST}" ]] && missing+=("DB_HOST")
    [[ -z "${MINIO_SERVER}" ]] && missing+=("MINIO_SERVER")
    [[ -z "${MINIO_ACCESS_KEY}" ]] && missing+=("MINIO_ACCESS_KEY")
    [[ -z "${MINIO_SECRET_KEY}" ]] && missing+=("MINIO_SECRET_KEY")
    [[ -z "${MINIO_BUCKET}" ]] && missing+=("MINIO_BUCKET")

    if [[ -z "${ALL_DATABASES}" ]] && [[ -z "${DB_NAME}" ]]; then
        missing+=("DB_NAME or ALL_DATABASES")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required environment variables: ${missing[*]}"
        exit 1
    fi
}

# =============================================================================
# Backup Functions
# =============================================================================
backup_single_database() {
    local db_name="$1"
    log_info "Backing up database: ${db_name}"

    if mysqldump \
        --user="${DB_USER}" \
        --password="${DB_PASS}" \
        --host="${DB_HOST}" \
        --port="${DB_PORT}" \
        --single-transaction \
        --routines \
        --triggers \
        --events \
        "$@" \
        "${db_name}" > "${BACKUP_DIR}/${db_name}.sql" 2>/dev/null; then
        log_info "Successfully backed up: ${db_name}"
        return 0
    else
        log_error "Failed to backup: ${db_name}"
        return 1
    fi
}

backup_all_databases() {
    log_info "Starting backup of all databases..."

    # Get list of databases
    local databases
    databases=$(mysql \
        --user="${DB_USER}" \
        --password="${DB_PASS}" \
        --host="${DB_HOST}" \
        --port="${DB_PORT}" \
        -N -e "SHOW DATABASES;" 2>/dev/null)

    local backup_count=0
    local skip_count=0

    for db in ${databases}; do
        # Skip system databases
        if [[ "${db}" == "information_schema" ]] || \
           [[ "${db}" == "performance_schema" ]] || \
           [[ "${db}" == "mysql" ]] || \
           [[ "${db}" == "sys" ]] || \
           [[ "${db}" == _* ]] || \
           [[ "${db}" == "${IGNORE_DATABASE}" ]]; then
            log_info "Skipping system/ignored database: ${db}"
            ((skip_count++))
            continue
        fi

        if backup_single_database "${db}"; then
            ((backup_count++))
        fi
    done

    log_info "Backup complete: ${backup_count} databases backed up, ${skip_count} skipped"
}

# =============================================================================
# MinIO Functions
# =============================================================================
configure_minio() {
    log_info "Configuring MinIO client..."

    if mc config host add backup \
        "${MINIO_SERVER}" \
        "${MINIO_ACCESS_KEY}" \
        "${MINIO_SECRET_KEY}" \
        --api "${MINIO_API_VERSION}" > /dev/null 2>&1; then
        log_info "MinIO client configured successfully"
    else
        log_error "Failed to configure MinIO client"
        exit 1
    fi
}

upload_to_minio() {
    log_info "Compressing backup files..."

    cd /
    if tar -zcf "${BACKUP_FILE}" mysqldump; then
        log_info "Backup compressed: ${BACKUP_FILE}"
    else
        log_error "Failed to compress backup"
        exit 1
    fi

    # Create bucket if not exists (ignore error if exists)
    log_info "Ensuring bucket exists: ${MINIO_BUCKET}"
    mc mb "backup/${MINIO_BUCKET}" 2>/dev/null || true

    # Upload backup
    log_info "Uploading backup to MinIO..."
    if mc cp "${BACKUP_FILE}" "backup/${MINIO_BUCKET}/"; then
        log_info "Backup uploaded successfully: ${BACKUP_FILE}"
    else
        log_error "Failed to upload backup"
        exit 1
    fi

    # Cleanup old backups
    log_info "Cleaning up backups older than ${BACKUP_RETENTION_DAYS} days..."
    mc rm --recursive --force --older-than "${BACKUP_RETENTION_DAYS}d" "backup/${MINIO_BUCKET}/" 2>/dev/null || true

    # Cleanup local files
    log_info "Cleaning up local files..."
    rm -f "/${BACKUP_FILE}"
    rm -rf "${BACKUP_DIR:?}"/*
}

# =============================================================================
# Main
# =============================================================================
main() {
    log_info "=========================================="
    log_info "MySQL Backup to MinIO - Starting"
    log_info "=========================================="
    log_info "Namespace: ${NAME_SPACE}"
    log_info "Database Host: ${DB_HOST}:${DB_PORT}"
    log_info "MinIO Server: ${MINIO_SERVER}"
    log_info "MinIO Bucket: ${MINIO_BUCKET}"
    log_info "Retention Days: ${BACKUP_RETENTION_DAYS}"
    log_info "=========================================="

    # Validate environment
    validate_env

    # Perform backup
    if [[ -n "${ALL_DATABASES}" ]] && [[ "${ALL_DATABASES}" == "true" ]]; then
        backup_all_databases
    else
        backup_single_database "${DB_NAME}" "$@"
    fi

    # Configure and upload to MinIO
    configure_minio
    upload_to_minio

    log_info "=========================================="
    log_info "MySQL Backup to MinIO - Completed"
    log_info "=========================================="
}

# Run main function
main "$@"
