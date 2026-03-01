#!/usr/bin/env bash
# validate.sh — End-to-end validation for kube-mysqldump-tominio-cron
#
# What this script does:
#   1. Ensures 'mc' (MinIO client) is available
#   2. Prepares a test bucket on the 'public' MinIO instance
#   3. Pre-pulls the backup image to the K3s node
#   4. Deploys a temporary MySQL pod in K3s
#   5. Verifies MySQL is actually ready to accept queries
#   6. Runs the backup image as a one-shot Job
#   7. Verifies the backup file was uploaded to MinIO via 'mc ls'
#   8. Cleans up all test resources (on success AND failure)
#
# Requirements: kubectl, curl, bash >= 4
# Usage:
#   ./test/validate.sh
#   BACKUP_IMAGE=zot.treesir.pub:5000/yangzun/kube-mysqldump-tominio-cron:test ./test/validate.sh

set -euo pipefail

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
NAMESPACE="mysqldump-verify"
MINIO_ALIAS="validate-public"
MINIO_URL="http://10.16.110.110:19000"
MINIO_ACCESS_KEY="admin"
MINIO_SECRET_KEY='evnh7UFKpqlRBuD#K#7xOh8q'
MINIO_BUCKET="mysqldump-verify"
MYSQL_ROOT_PASS="ValidatePass123"
BACKUP_IMAGE="${BACKUP_IMAGE:-zot.treesir.pub:5000/yangzun/kube-mysqldump-tominio-cron:verify}"
JOB_NAME="mysqldump-validate"
MC_BIN=""
TIMEOUT_IMAGE_PULL=180   # seconds to pre-pull backup image
TIMEOUT_MYSQL=120        # seconds to wait for MySQL pod Ready
TIMEOUT_MYSQL_QUERY=60   # seconds to wait for MySQL to accept actual queries
TIMEOUT_JOB=300          # seconds to wait for backup job to complete

# ---------------------------------------------------------------------------
# Colors
# ---------------------------------------------------------------------------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
step()  { echo -e "\n${GREEN}====> $*${NC}"; }

# ---------------------------------------------------------------------------
# Cleanup (always runs)
# ---------------------------------------------------------------------------
cleanup() {
  step "Cleanup"
  info "Deleting namespace ${NAMESPACE} ..."
  kubectl delete namespace "${NAMESPACE}" --ignore-not-found --timeout=60s 2>/dev/null || true

  if [[ -n "${MC_BIN}" && "${MC_BIN}" == /tmp/* ]]; then
    info "Removing temporary mc binary ..."
    rm -f "${MC_BIN}"
  fi

  if [[ -n "${MC_BIN}" ]] && "${MC_BIN}" alias list "${MINIO_ALIAS}" &>/dev/null 2>&1; then
    info "Removing MinIO alias ${MINIO_ALIAS} ..."
    "${MC_BIN}" alias remove "${MINIO_ALIAS}" 2>/dev/null || true
  fi

  if [[ -n "${MC_BIN}" ]] && "${MC_BIN}" ls "${MINIO_ALIAS}/${MINIO_BUCKET}" &>/dev/null 2>&1; then
    info "Removing test bucket ${MINIO_BUCKET} ..."
    "${MC_BIN}" rb --force "${MINIO_ALIAS}/${MINIO_BUCKET}" 2>/dev/null || true
  fi
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Step 1: Ensure mc is available
# ---------------------------------------------------------------------------
step "Step 1: Ensure MinIO client (mc)"

ensure_mc() {
  if command -v mc &>/dev/null; then
    MC_BIN="mc"
    info "Found mc at $(command -v mc)"
    return
  fi

  warn "mc not found in PATH, downloading to /tmp ..."
  local arch
  arch="$(uname -m)"
  case "${arch}" in
    x86_64)  arch="amd64" ;;
    aarch64) arch="arm64" ;;
    *) error "Unsupported arch: ${arch}"; exit 1 ;;
  esac

  local mc_url="https://dl.min.io/client/mc/release/linux-${arch}/mc"
  MC_BIN="/tmp/mc-validate-$$"
  curl -fsSL "${mc_url}" -o "${MC_BIN}"
  chmod +x "${MC_BIN}"
  info "mc downloaded to ${MC_BIN}"
}
ensure_mc

# ---------------------------------------------------------------------------
# Step 2: Configure MinIO alias and create test bucket
# ---------------------------------------------------------------------------
step "Step 2: Configure MinIO and create test bucket"

info "Adding alias '${MINIO_ALIAS}' → ${MINIO_URL}"
"${MC_BIN}" alias set "${MINIO_ALIAS}" \
  "${MINIO_URL}" \
  "${MINIO_ACCESS_KEY}" \
  "${MINIO_SECRET_KEY}" \
  --api S3v4 --path auto

info "Verifying MinIO connectivity ..."
"${MC_BIN}" admin info "${MINIO_ALIAS}" --json | grep -q '"status":"success"' \
  || { error "Cannot reach MinIO at ${MINIO_URL}"; exit 1; }

info "Creating test bucket: ${MINIO_BUCKET}"
"${MC_BIN}" mb "${MINIO_ALIAS}/${MINIO_BUCKET}" 2>/dev/null || true
info "Bucket created or already exists."
info "Bucket created."

# ---------------------------------------------------------------------------
# Step 3: Pre-pull backup image to K3s node
# ---------------------------------------------------------------------------
step "Step 3: Pre-pull backup image to K3s node"
info "Image: ${BACKUP_IMAGE}"
info "Running a no-op pod to trigger image pull (timeout: ${TIMEOUT_IMAGE_PULL}s) ..."

kubectl create namespace "${NAMESPACE}" 2>/dev/null || true

# Use a temporary pod to warm the image cache on the node
kubectl run image-pull-probe \
  -n "${NAMESPACE}" \
  --image="${BACKUP_IMAGE}" \
  --image-pull-policy=Always \
  --restart=Never \
  --command -- /bin/sh -c "echo image-ready" \
  --timeout="${TIMEOUT_IMAGE_PULL}s" 2>/dev/null || true

# Wait for it to complete (image pulled + ran entrypoint)
kubectl wait -n "${NAMESPACE}" pod/image-pull-probe \
  --for=jsonpath='{.status.phase}'=Succeeded \
  --timeout="${TIMEOUT_IMAGE_PULL}s" 2>/dev/null \
  || kubectl wait -n "${NAMESPACE}" pod/image-pull-probe \
       --for=jsonpath='{.status.phase}'=Failed \
       --timeout=10s 2>/dev/null \
  || true

kubectl delete pod image-pull-probe -n "${NAMESPACE}" --ignore-not-found 2>/dev/null || true
info "Image pre-pull complete."

# ---------------------------------------------------------------------------
# Step 4: Deploy test MySQL
# ---------------------------------------------------------------------------
step "Step 4: Deploy test MySQL in K3s (namespace: ${NAMESPACE})"

kubectl apply -n "${NAMESPACE}" -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: mysql-config
data:
  my.cnf: |
    [mysqld]
    default_authentication_plugin=mysql_native_password
---
apiVersion: v1
kind: Secret
metadata:
  name: mysql-secret
type: Opaque
stringData:
  password: "${MYSQL_ROOT_PASS}"
---
apiVersion: v1
kind: Pod
metadata:
  name: mysql
  labels:
    app: mysql
spec:
  containers:
  - name: mysql
    image: mysql:8.0
    env:
    - name: MYSQL_ROOT_PASSWORD
      valueFrom:
        secretKeyRef:
          name: mysql-secret
          key: password
    - name: MYSQL_DATABASE
      value: testdb
    ports:
    - containerPort: 3306
    volumeMounts:
    - name: mysql-config
      mountPath: /etc/mysql/conf.d
    readinessProbe:
      exec:
        command:
        - mysqladmin
        - ping
        - -h
        - "127.0.0.1"
        - -uroot
        - -p${MYSQL_ROOT_PASS}
        - --connect-timeout=3
      initialDelaySeconds: 15
      periodSeconds: 5
      timeoutSeconds: 5
      failureThreshold: 10
  volumes:
  - name: mysql-config
    configMap:
      name: mysql-config
---
apiVersion: v1
kind: Service
metadata:
  name: mysql-server
spec:
  selector:
    app: mysql
  ports:
  - port: 3306
    targetPort: 3306
EOF

info "Waiting for MySQL pod to be Ready (timeout: ${TIMEOUT_MYSQL}s) ..."
kubectl wait -n "${NAMESPACE}" pod/mysql \
  --for=condition=Ready \
  --timeout="${TIMEOUT_MYSQL}s"
info "MySQL pod is Ready."

# Additional check: wait until MySQL actually accepts queries
info "Verifying MySQL accepts queries via kubectl exec ..."
deadline=$((SECONDS + TIMEOUT_MYSQL_QUERY))
until kubectl exec -n "${NAMESPACE}" pod/mysql -- \
      mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "SELECT 1;" &>/dev/null; do
  if [[ ${SECONDS} -ge ${deadline} ]]; then
    error "MySQL did not accept queries within ${TIMEOUT_MYSQL_QUERY}s"
    exit 1
  fi
  info "  Waiting for MySQL query readiness ..."
  sleep 3
done
info "MySQL is ready and accepting queries."

# Create a test table in testdb to ensure mysqldump has something to backup
info "Creating test table in testdb ..."
kubectl exec -n "${NAMESPACE}" pod/mysql -- \
  mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "
    USE testdb;
    CREATE TABLE IF NOT EXISTS test_table (id INT PRIMARY KEY, name VARCHAR(50));
    INSERT INTO test_table VALUES (1, 'test_data');
  " 2>/dev/null || true
info "Test table created."

# ---------------------------------------------------------------------------
# Step 5: Create secrets, configmap, and run backup Job
# ---------------------------------------------------------------------------
step "Step 5: Run backup Job"

# Delete any existing job before creating new one (Job spec is immutable)
kubectl delete job "${JOB_NAME}" -n "${NAMESPACE}" --ignore-not-found 2>/dev/null || true

kubectl apply -n "${NAMESPACE}" -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: minio-secret
type: Opaque
stringData:
  server: "${MINIO_URL}"
  access_key: "${MINIO_ACCESS_KEY}"
  secret_key: "${MINIO_SECRET_KEY}"
  bucket: "${MINIO_BUCKET}"
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: mysqldump-config
data:
  db_host: "mysql-server"
  db_port: "3306"
  all_databases: "true"
  backup_retention_days: "7"
---
apiVersion: batch/v1
kind: Job
metadata:
  name: ${JOB_NAME}
spec:
  backoffLimit: 0
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: mysqldump
        image: ${BACKUP_IMAGE}
        imagePullPolicy: IfNotPresent
        env:
        - name: NAME_SPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: DB_HOST
          valueFrom:
            configMapKeyRef:
              name: mysqldump-config
              key: db_host
        - name: DB_PORT
          valueFrom:
            configMapKeyRef:
              name: mysqldump-config
              key: db_port
        - name: DB_USER
          value: "root"
        - name: DB_PASS
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: password
        - name: ALL_DATABASES
          valueFrom:
            configMapKeyRef:
              name: mysqldump-config
              key: all_databases
        - name: BACKUP_RETENTION_DAYS
          valueFrom:
            configMapKeyRef:
              name: mysqldump-config
              key: backup_retention_days
        - name: MINIO_SERVER
          valueFrom:
            secretKeyRef:
              name: minio-secret
              key: server
        - name: MINIO_ACCESS_KEY
          valueFrom:
            secretKeyRef:
              name: minio-secret
              key: access_key
        - name: MINIO_SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: minio-secret
              key: secret_key
        - name: MINIO_BUCKET
          valueFrom:
            secretKeyRef:
              name: minio-secret
              key: bucket
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        volumeMounts:
        - mountPath: /mysqldump
          name: work
      volumes:
      - name: work
        emptyDir:
          sizeLimit: 1Gi
EOF

info "Waiting for backup Job to complete (timeout: ${TIMEOUT_JOB}s) ..."
kubectl wait -n "${NAMESPACE}" "job/${JOB_NAME}" \
  --for=condition=Complete \
  --timeout="${TIMEOUT_JOB}s" || {
    error "Backup job did not complete. Printing pod logs:"
    kubectl logs -n "${NAMESPACE}" \
      -l "job-name=${JOB_NAME}" --tail=80 2>/dev/null || true
    echo ""
    error "Pod status:"
    kubectl get pods -n "${NAMESPACE}" -l "job-name=${JOB_NAME}" 2>/dev/null || true
    exit 1
  }

info "Job completed. Logs:"
kubectl logs -n "${NAMESPACE}" -l "job-name=${JOB_NAME}" --tail=80

# ---------------------------------------------------------------------------
# Step 6: Verify backup file in MinIO
# ---------------------------------------------------------------------------
step "Step 6: Verify backup in MinIO"

info "Listing objects in ${MINIO_ALIAS}/${MINIO_BUCKET} ..."
OBJECTS=$("${MC_BIN}" ls "${MINIO_ALIAS}/${MINIO_BUCKET}" 2>&1)

if echo "${OBJECTS}" | grep -q "mysqldump"; then
  echo "${OBJECTS}"
  FILE_COUNT=$(echo "${OBJECTS}" | grep -c "mysqldump")
  FILE_SIZE=$(echo "${OBJECTS}" | grep "mysqldump" | awk '{print $3, $4}' | head -1)
  echo ""
  echo -e "${GREEN}[PASS]${NC} Backup image is working correctly."
  echo -e "       Image      : ${BACKUP_IMAGE}"
  echo -e "       MinIO      : ${MINIO_URL}/${MINIO_BUCKET}"
  echo -e "       Files      : ${FILE_COUNT}"
  echo -e "       Size       : ${FILE_SIZE}"
else
  error "No backup files found in MinIO bucket!"
  echo "${OBJECTS}"
  exit 1
fi
