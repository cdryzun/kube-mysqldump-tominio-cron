FROM alpine:3.4
ENV MINIO_SERVER=""
ENV MINIO_BUCKET="mysql-backups"
ENV MINIO_ACCESS_KEY=""
ENV MINIO_SECRET_KEY=""
ENV MINIO_API_VERSION="S3v4"
RUN apk add --update ca-certificates openssl && update-ca-certificates \
    && apk add --update mysql-client bash openssh-client \
    && rm -rf /var/cache/apk/*
COPY dump.sh /
COPY import.sh /
RUN wget https://dl.minio.io/client/mc/release/linux-amd64/mc -O /usr/bin/mc && \
    chmod +x /usr/bin/mc
ENTRYPOINT ["/dump.sh"]
