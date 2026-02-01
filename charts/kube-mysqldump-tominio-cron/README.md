# kube-mysqldump-tominio-cron

A Helm chart for MySQL backup to MinIO in Kubernetes.

## Installation

```bash
helm install mysql-backup ./charts/kube-mysqldump-tominio-cron \
  --set mysql.host=mysql-server \
  --set mysql.user=root \
  --set mysql.password=your-password \
  --set minio.server=http://minio:9000 \
  --set minio.accessKey=minio \
  --set minio.secretKey=minio123 \
  --set minio.bucket=mysql-backups
```

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Image repository | `cdryzun/kube-mysqldump-tominio-cron` |
| `image.tag` | Image tag | `latest` |
| `schedule.cron` | Cron schedule | `0 4 * * *` |
| `schedule.timeZone` | Timezone | `Asia/Shanghai` |
| `mysql.host` | MySQL host | `mysql-server` |
| `mysql.port` | MySQL port | `3306` |
| `mysql.user` | MySQL user | `root` |
| `mysql.password` | MySQL password | `""` |
| `mysql.allDatabases` | Backup all databases | `true` |
| `minio.server` | MinIO server URL | `http://minio:9000` |
| `minio.accessKey` | MinIO access key | `""` |
| `minio.secretKey` | MinIO secret key | `""` |
| `minio.bucket` | MinIO bucket | `mysql-backups` |
| `backup.retentionDays` | Backup retention days | `7` |

## Using Existing Secrets

```yaml
mysql:
  existingSecret: my-mysql-secret
  existingSecretUsernameKey: username
  existingSecretPasswordKey: password

minio:
  existingSecret: my-minio-secret
  existingSecretServerKey: server
  existingSecretAccessKeyKey: access_key
  existingSecretSecretKeyKey: secret_key
  existingSecretBucketKey: bucket
```
