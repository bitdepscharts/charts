{{/* vim: set filetype=mustache: */}}
{{/*
  Overrides common template functions to support both library and direct modes.
  Takes component into account.
*/}}

{{- define "raw.chart.name" -}}
  {{- ternary .Chart.Name .Values.chartName .Chart.IsRoot -}}
{{- end -}}

{{/*
Expand the name of the chart. Compatible with original common.names.name
*/}}
{{- define "common.names.name" -}}
  {{- default (include "raw.chart.name" .) .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "common.names.chart" -}}
  {{- printf "%s-%s" (include "raw.chart.name" .) .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
