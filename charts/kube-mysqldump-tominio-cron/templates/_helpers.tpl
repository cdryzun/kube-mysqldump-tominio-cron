{{/*
Expand the name of the chart.
*/}}
{{- define "kube-mysqldump-tominio-cron.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "kube-mysqldump-tominio-cron.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "kube-mysqldump-tominio-cron.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "kube-mysqldump-tominio-cron.labels" -}}
helm.sh/chart: {{ include "kube-mysqldump-tominio-cron.chart" . }}
{{ include "kube-mysqldump-tominio-cron.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.labels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "kube-mysqldump-tominio-cron.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kube-mysqldump-tominio-cron.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "kube-mysqldump-tominio-cron.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "kube-mysqldump-tominio-cron.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
MySQL secret name
*/}}
{{- define "kube-mysqldump-tominio-cron.mysqlSecretName" -}}
{{- if .Values.mysql.existingSecret }}
{{- .Values.mysql.existingSecret }}
{{- else }}
{{- include "kube-mysqldump-tominio-cron.fullname" . }}-mysql
{{- end }}
{{- end }}

{{/*
MinIO secret name
*/}}
{{- define "kube-mysqldump-tominio-cron.minioSecretName" -}}
{{- if .Values.minio.existingSecret }}
{{- .Values.minio.existingSecret }}
{{- else }}
{{- include "kube-mysqldump-tominio-cron.fullname" . }}-minio
{{- end }}
{{- end }}
