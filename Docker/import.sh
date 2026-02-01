#!/bin/bash
set -euo pipefail

# =============================================================================
# MySQL Import Script for Kubernetes
# Imports MySQL databases from backup files
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
BACKUP_DIR="/mysqldump"

# =============================================================================
# Validation
# =============================================================================
validate_env() {
    local missing=()

    [[ -z "${DB_USER}" ]] && missing+=("DB_USER")
    [[ -z "${DB_PASS}" ]] && missing+=("DB_PASS")
    [[ -z "${DB_HOST}" ]] && missing+=("DB_HOST")

    if [[ -z "${ALL_DATABASES}" ]] && [[ -z "${DB_NAME}" ]]; then
        missing+=("DB_NAME or ALL_DATABASES")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required environment variables: ${missing[*]}"
        exit 1
    fi
}

# =============================================================================
# Import Functions
# =============================================================================
import_single_database() {
    local db_name="$1"
    local sql_file="${BACKUP_DIR}/${db_name}.sql"

    if [[ ! -f "${sql_file}" ]]; then
        log_error "SQL file not found: ${sql_file}"
        return 1
    fi

    log_info "Importing database: ${db_name}"

    if mysql \
        --user="${DB_USER}" \
        --password="${DB_PASS}" \
        --host="${DB_HOST}" \
        --port="${DB_PORT}" \
        "$@" \
        "${db_name}" < "${sql_file}" 2>/dev/null; then
        log_info "Successfully imported: ${db_name}"
        return 0
    else
        log_error "Failed to import: ${db_name}"
        return 1
    fi
}

import_all_databases() {
    log_info "Starting import of all databases..."

    if [[ ! -d "${BACKUP_DIR}" ]]; then
        log_error "Backup directory not found: ${BACKUP_DIR}"
        exit 1
    fi

    local import_count=0
    local skip_count=0
    local fail_count=0

    for sql_file in "${BACKUP_DIR}"/*.sql; do
        [[ -f "${sql_file}" ]] || continue

        local db_name
        db_name=$(basename "${sql_file}" .sql)

        # Skip system databases
        if [[ "${db_name}" == "information_schema" ]] || \
           [[ "${db_name}" == "performance_schema" ]] || \
           [[ "${db_name}" == "mysql" ]] || \
           [[ "${db_name}" == "sys" ]] || \
           [[ "${db_name}" == _* ]]; then
            log_info "Skipping system database: ${db_name}"
            ((skip_count++))
            continue
        fi

        # Create database if not exists
        log_info "Creating database if not exists: ${db_name}"
        mysql \
            --user="${DB_USER}" \
            --password="${DB_PASS}" \
            --host="${DB_HOST}" \
            --port="${DB_PORT}" \
            -e "CREATE DATABASE IF NOT EXISTS \`${db_name}\`;" 2>/dev/null || true

        if import_single_database "${db_name}"; then
            ((import_count++))
        else
            ((fail_count++))
        fi
    done

    log_info "Import complete: ${import_count} imported, ${skip_count} skipped, ${fail_count} failed"

    if [[ ${fail_count} -gt 0 ]]; then
        return 1
    fi
}

# =============================================================================
# Main
# =============================================================================
main() {
    log_info "=========================================="
    log_info "MySQL Import - Starting"
    log_info "=========================================="
    log_info "Database Host: ${DB_HOST}:${DB_PORT}"
    log_info "Backup Directory: ${BACKUP_DIR}"
    log_info "=========================================="

    # Validate environment
    validate_env

    # Perform import
    if [[ -n "${ALL_DATABASES}" ]] && [[ "${ALL_DATABASES}" == "true" ]]; then
        import_all_databases
    else
        import_single_database "${DB_NAME}" "$@"
    fi

    log_info "=========================================="
    log_info "MySQL Import - Completed"
    log_info "=========================================="
}

# Run main function
main "$@"
