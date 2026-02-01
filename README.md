# kube-mysqldump-tominio-cron

[![Docker Image](https://img.shields.io/docker/v/cdryzun/kube-mysqldump-tominio-cron?sort=semver&label=Docker%20Image)](https://hub.docker.com/r/cdryzun/kube-mysqldump-tominio-cron)
[![Docker Pulls](https://img.shields.io/docker/pulls/cdryzun/kube-mysqldump-tominio-cron)](https://hub.docker.com/r/cdryzun/kube-mysqldump-tominio-cron)
[![License](https://img.shields.io/github/license/cdryzun/kube-mysqldump-tominio-cron)](LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/cdryzun/kube-mysqldump-tominio-cron?style=social)](https://github.com/cdryzun/kube-mysqldump-tominio-cron)

[English](#english) | [中文](#中文)

---

## English

A lightweight Kubernetes CronJob solution for automated MySQL database backups to MinIO (S3-compatible) object storage.

### Features

- **Automated Scheduling** - Kubernetes CronJob for scheduled backups
- **Flexible Backup Options** - Single database or all databases backup
- **S3-Compatible Storage** - Upload backups to MinIO or any S3-compatible storage
- **Automatic Cleanup** - Configurable retention period (default: 7 days)
- **Lightweight** - Based on Alpine Linux (~50MB image)
- **Multi-Architecture** - Supports amd64 and arm64
- **Helm Chart** - Easy deployment with Helm
- **Notification Support** - Slack, DingTalk, and webhook notifications

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Kubernetes Cluster                          │
│  ┌───────────────┐    ┌───────────────┐    ┌───────────────┐    │
│  │   CronJob     │───▶│  MySQL Pod    │    │   MinIO Pod   │    │
│  │  (Scheduled)  │    │  (Database)   │    │  (Storage)    │    │
│  └───────┬───────┘    └───────────────┘    └───────▲───────┘    │
│          │                                         │            │
│          │         ┌───────────────┐               │            │
│          └────────▶│  Backup Job   │───────────────┘            │
│                    │  1. mysqldump │                            │
│                    │  2. compress  │                            │
│                    │  3. upload    │                            │
│                    │  4. cleanup   │                            │
│                    └───────────────┘                            │
└─────────────────────────────────────────────────────────────────┘
```

### Quick Start

#### Option 1: Using Helm (Recommended)

```bash
# Add the Helm repository (if published)
# helm repo add kube-mysqldump https://cdryzun.github.io/kube-mysqldump-tominio-cron

# Install with Helm
helm install mysql-backup ./charts/kube-mysqldump-tominio-cron \
  --set mysql.host=mysql-server \
  --set mysql.user=root \
  --set mysql.password=your-password \
  --set minio.server=http://minio:9000 \
  --set minio.accessKey=minio \
  --set minio.secretKey=minio123 \
  --set minio.bucket=mysql-backups
```

#### Option 2: Using kubectl

```bash
# Apply the example configuration
kubectl apply -f test/backup-job.yaml
```

### Configuration

#### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DB_HOST` | Yes | - | MySQL host address |
| `DB_USER` | Yes | - | MySQL username |
| `DB_PASS` | Yes | - | MySQL password |
| `DB_NAME` | No | - | Database name (for single DB backup) |
| `ALL_DATABASES` | No | - | Set to "true" for all databases backup |
| `IGNORE_DATABASE` | No | - | Database name to ignore |
| `MINIO_SERVER` | Yes | - | MinIO server URL |
| `MINIO_ACCESS_KEY` | Yes | - | MinIO access key |
| `MINIO_SECRET_KEY` | Yes | - | MinIO secret key |
| `MINIO_BUCKET` | Yes | `mysql-backups` | MinIO bucket name/path |
| `MINIO_API_VERSION` | No | `S3v4` | MinIO API version |
| `BACKUP_RETENTION_DAYS` | No | `7` | Days to retain backups |

#### Kubernetes Manifest Example

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: mysqldump
spec:
  schedule: "0 4 * * *"  # Daily at 4:00 AM
  failedJobsHistoryLimit: 1
  successfulJobsHistoryLimit: 3
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: mysqldump
            image: cdryzun/kube-mysqldump-tominio-cron:latest
            env:
            - name: DB_HOST
              value: "mysql-server"
            - name: DB_USER
              value: "root"
            - name: DB_PASS
              valueFrom:
                secretKeyRef:
                  name: mysql-secret
                  key: password
            - name: ALL_DATABASES
              value: "true"
            - name: MINIO_SERVER
              value: "http://minio:9000"
            - name: MINIO_ACCESS_KEY
              valueFrom:
                secretKeyRef:
                  name: minio-secret
                  key: access-key
            - name: MINIO_SECRET_KEY
              valueFrom:
                secretKeyRef:
                  name: minio-secret
                  key: secret-key
            - name: MINIO_BUCKET
              value: "mysql-backups/production"
            volumeMounts:
            - mountPath: /mysqldump
              name: mysqldump
          volumes:
          - name: mysqldump
            emptyDir: {}
          restartPolicy: OnFailure
```

### Manual Backup

Trigger a backup manually:

```bash
kubectl create job --from=cronjob/mysqldump manual-backup-$(date +%s)
```

### Restore from Backup

```bash
# Download backup from MinIO
mc cp minio/mysql-backups/mysqldump-20240101120000.tar.gz .

# Extract
tar -xzf mysqldump-20240101120000.tar.gz

# Restore
mysql -h <host> -u <user> -p < mysqldump/database_name.sql
```

### Development

```bash
# Build locally
docker build -t kube-mysqldump-tominio-cron:dev ./Docker

# Test with docker-compose
docker-compose -f test/docker-compose.yaml up
```

### Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) for details.

### License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 中文

一个轻量级的 Kubernetes CronJob 解决方案，用于自动将 MySQL 数据库备份到 MinIO（S3 兼容）对象存储。

### 特性

- **自动调度** - 使用 Kubernetes CronJob 进行定时备份
- **灵活的备份选项** - 支持单个数据库或全部数据库备份
- **S3 兼容存储** - 上传备份到 MinIO 或任何 S3 兼容存储
- **自动清理** - 可配置的保留期限（默认：7 天）
- **轻量级** - 基于 Alpine Linux（约 50MB 镜像）
- **多架构** - 支持 amd64 和 arm64
- **Helm Chart** - 使用 Helm 轻松部署
- **通知支持** - 支持 Slack、钉钉和 Webhook 通知

### 架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                     Kubernetes 集群                              │
│  ┌───────────────┐    ┌───────────────┐    ┌───────────────┐     │
│  │   CronJob     │───▶│  MySQL Pod    │    │   MinIO Pod   │     │
│  │  (定时任务)    │    │  (数据库)     │   │  (对象存储)   │      │
│  └───────┬───────┘    └───────────────┘    └───────▲───────┘    │
│          │                                         │            │
│          │         ┌───────────────┐               │            │
│          └────────▶│   备份任务     │───────────────┘            │
│                    │  1. mysqldump │                             │
│                    │  2. 压缩       │                            │
│                    │  3. 上传       │                            │
│                    │  4. 清理旧备份  │                            │
│                    └───────────────┘                            │
└─────────────────────────────────────────────────────────────────┘
```

### 快速开始

#### 方式一：使用 Helm（推荐）

```bash
# 使用 Helm 安装
helm install mysql-backup ./charts/kube-mysqldump-tominio-cron \
  --set mysql.host=mysql-server \
  --set mysql.user=root \
  --set mysql.password=your-password \
  --set minio.server=http://minio:9000 \
  --set minio.accessKey=minio \
  --set minio.secretKey=minio123 \
  --set minio.bucket=mysql-backups
```

#### 方式二：使用 kubectl

```bash
# 应用示例配置
kubectl apply -f test/backup-job.yaml
```

### 配置说明

#### 环境变量

| 变量 | 必需 | 默认值 | 描述 |
|------|------|--------|------|
| `DB_HOST` | 是 | - | MySQL 主机地址 |
| `DB_USER` | 是 | - | MySQL 用户名 |
| `DB_PASS` | 是 | - | MySQL 密码 |
| `DB_NAME` | 否 | - | 数据库名称（单库备份时使用） |
| `ALL_DATABASES` | 否 | - | 设置为 "true" 备份所有数据库 |
| `IGNORE_DATABASE` | 否 | - | 要忽略的数据库名称 |
| `MINIO_SERVER` | 是 | - | MinIO 服务器 URL |
| `MINIO_ACCESS_KEY` | 是 | - | MinIO 访问密钥 |
| `MINIO_SECRET_KEY` | 是 | - | MinIO 密钥 |
| `MINIO_BUCKET` | 是 | `mysql-backups` | MinIO 存储桶名称/路径 |
| `MINIO_API_VERSION` | 否 | `S3v4` | MinIO API 版本 |
| `BACKUP_RETENTION_DAYS` | 否 | `7` | 备份保留天数 |

### 手动触发备份

```bash
kubectl create job --from=cronjob/mysqldump manual-backup-$(date +%s)
```

### 从备份恢复

```bash
# 从 MinIO 下载备份
mc cp minio/mysql-backups/mysqldump-20240101120000.tar.gz .

# 解压
tar -xzf mysqldump-20240101120000.tar.gz

# 恢复
mysql -h <主机> -u <用户> -p < mysqldump/database_name.sql
```

### 开发

```bash
# 本地构建
docker build -t kube-mysqldump-tominio-cron:dev ./Docker

# 使用 docker-compose 测试
docker-compose -f test/docker-compose.yaml up
```

### 贡献

欢迎贡献！请阅读我们的[贡献指南](CONTRIBUTING.md)了解详情。

### 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件。
