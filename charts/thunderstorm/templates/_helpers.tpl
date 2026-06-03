{{/*
Expand the name of the chart.
*/}}
{{- define "thunderstorm.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "thunderstorm.fullname" -}}
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
Chart label.
*/}}
{{- define "thunderstorm.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "thunderstorm.labels" -}}
helm.sh/chart: {{ include "thunderstorm.chart" . }}
{{ include "thunderstorm.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "thunderstorm.selectorLabels" -}}
app.kubernetes.io/name: {{ include "thunderstorm.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Service account name.
*/}}
{{- define "thunderstorm.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "thunderstorm.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Contract token secret name.
*/}}
{{- define "thunderstorm.contractTokenSecretName" -}}
{{- if .Values.contractToken.existingSecret }}
{{- .Values.contractToken.existingSecret }}
{{- else }}
{{- printf "%s-contract-token" (include "thunderstorm.fullname" .) }}
{{- end }}
{{- end }}

{{/*
TLS secret name.
*/}}
{{- define "thunderstorm.tlsSecretName" -}}
{{- if .Values.tls.existingSecret }}
{{- .Values.tls.existingSecret }}
{{- else }}
{{- printf "%s-tls" (include "thunderstorm.fullname" .) }}
{{- end }}
{{- end }}
