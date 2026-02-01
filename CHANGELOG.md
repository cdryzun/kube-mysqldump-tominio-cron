# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-02-01

### Added
- MIT License file
- CONTRIBUTING.md with contribution guidelines (bilingual)
- CHANGELOG.md for tracking changes
- .gitignore file
- Helm Chart for easier deployment
- Multi-architecture Docker image support (amd64/arm64)
- Configurable backup retention period via `BACKUP_RETENTION_DAYS` environment variable
- Comprehensive bilingual README (English/Chinese)
- Resource limits and requests in Kubernetes manifests
- Trivy security scanning in CI/CD pipeline
- ShellCheck linting for shell scripts
- GitHub Container Registry (GHCR) support

### Changed
- Upgraded base image from Alpine 3.4 to Alpine 3.19
- Upgraded Kubernetes CronJob API from `batch/v1beta1` to `batch/v1`
- Improved error handling and logging in backup scripts with colored output
- Updated GitHub Actions to use latest action versions (v3/v4/v5)
- Enhanced CI/CD pipeline with multi-stage jobs
- Refactored dump.sh and import.sh with better structure and validation
- Updated MinIO client download to use curl instead of wget

### Fixed
- Shell script compatibility issues with strict mode (set -euo pipefail)
- MinIO client download URL for multi-architecture support

## [0.1.0] - 2023-06-26

### Added
- Initial release
- MySQL database backup to MinIO object storage
- Support for single database and all databases backup
- Kubernetes CronJob deployment
- Automatic cleanup of backups older than 7 days
- Basic CI/CD pipeline with GitHub Actions

[Unreleased]: https://github.com/cdryzun/kube-mysqldump-tominio-cron/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/cdryzun/kube-mysqldump-tominio-cron/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/cdryzun/kube-mysqldump-tominio-cron/releases/tag/v0.1.0
