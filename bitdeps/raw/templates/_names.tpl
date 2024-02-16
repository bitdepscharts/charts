{{/* vim: set filetype=mustache: */}}
{{/*
  Overrides common template functions to support both library and direct modes.
  Takes component into account.
*/}}

{{/*
Alias for the "common.names.name" template
*/}}
{{- define "app.name" -}}
  {{- template "common.names.name" . -}}
{{- end -}}

{{/*
Expand the name of the chart.
*/}}
{{- define "common.names.name" -}}
  {{- default .Values.chartName .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "common.names.chart" -}}
  {{- printf "%s-%s" .Values.chartName .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
