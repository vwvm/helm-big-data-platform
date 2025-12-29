{{/* 常用标签 */}}
{{- define "oracle23c.labels" -}}
app: oracle-23c
chart: {{ .Chart.Name }}-{{ .Chart.Version }}
heritage: {{ .Release.Service }}
release: {{ .Release.Name }}
{{- end }}

{{/* 选择器标签 */}}
{{- define "oracle23c.selectorLabels" -}}
app.kubernetes.io/name: {{ include "oracle23c.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/* 名称定义 */}}
{{- define "oracle23c.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* 完整名称 */}}
{{- define "oracle23c.fullname" -}}
{{- if .Values.fullnameOverride }}
{{ .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{ $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{ .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{ printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/* Chart名称和版本 */}}
{{- define "oracle23c.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}