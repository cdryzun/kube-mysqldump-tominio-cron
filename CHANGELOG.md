# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- MIT License file
- CONTRIBUTING.md with contribution guidelines (bilingual)
- CHANGELOG.md for tracking changes
- .gitignore file
- Helm Chart for easier deployment
- Multi-architecture Docker image support (amd64/arm64)
- Configurable backup retention period via `BACKUP_RETENTION_DAYS` environment variable
- Webhook notification support (Slack, DingTalk, Generic)
- Backup verification feature
- Comprehensive bilingual README (English/Chinese)

### Changed
- Upgraded base image from Alpine 3.4 to Alpine 3.19
- Upgraded Kubernetes CronJob API from `batch/v1beta1` to `batch/v1`
- Improved error handling and logging in backup scripts
- Updated GitHub Actions to use latest action versions
- Enhanced CI/CD pipeline with security scanning

### Fixed
- Shell script compatibility issues
- MinIO client download URL

## [0.1.0] - 2023-06-26

### Added
- Initial release
- MySQL database backup to MinIO object storage
- Support for single database and all databases backup
- Kubernetes CronJob deployment
- Automatic cleanup of backups older than 7 days
- Basic CI/CD pipeline with GitHub Actions

[Unreleased]: https://github.com/cdryzun/kube-mysqldump-tominio-cron/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/cdryzun/kube-mysqldump-tominio-cron/releases/tag/v0.1.0
