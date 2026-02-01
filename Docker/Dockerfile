FROM alpine:3.19

LABEL maintainer="cdryzun"
LABEL description="MySQL backup to MinIO for Kubernetes"
LABEL version="0.2.0"

# Environment variables with defaults
ENV MINIO_SERVER=""
ENV MINIO_BUCKET="mysql-backups"
ENV MINIO_ACCESS_KEY=""
ENV MINIO_SECRET_KEY=""
ENV MINIO_API_VERSION="S3v4"
ENV BACKUP_RETENTION_DAYS="7"

# Install dependencies
RUN apk add --no-cache \
    ca-certificates \
    openssl \
    mysql-client \
    bash \
    curl \
    tzdata \
    && update-ca-certificates

# Download and install MinIO client
ARG TARGETARCH
RUN case "${TARGETARCH}" in \
        "amd64") MC_ARCH="amd64" ;; \
        "arm64") MC_ARCH="arm64" ;; \
        *) MC_ARCH="amd64" ;; \
    esac && \
    curl -fsSL "https://dl.min.io/client/mc/release/linux-${MC_ARCH}/mc" -o /usr/bin/mc && \
    chmod +x /usr/bin/mc

# Copy scripts
COPY dump.sh /dump.sh
COPY import.sh /import.sh

# Make scripts executable
RUN chmod +x /dump.sh /import.sh

# Create backup directory
RUN mkdir -p /mysqldump

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD mc --version || exit 1

ENTRYPOINT ["/dump.sh"]
