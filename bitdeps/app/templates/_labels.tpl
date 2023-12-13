{{/* vim: set filetype=mustache: */}}

{{/*
Kubernetes standard labels (extended)
  {{ include "app.labels.standard" (dict "customLabels" .Values.commonLabels "context" $) -}}
*/}}
{{- define "app.labels.standard" -}}
  {{- $labels := include "common.labels.standard" . | fromYaml -}}
  {{- if .context._include.component -}}
    {{- $_ := set $labels "app.kubernetes.io/component" .context._include.component -}}
  {{- end -}}
  {{- $labels | toYaml -}}
{{- end -}}

{{/*
Labels used on immutable fields such as deploy.spec.selector.matchLabels or svc.spec.selector
  {{ include "app.labels.matchLabels" (dict "customLabels" .Values.podLabels "context" $) -}}
*/}}

{{- define "app.labels.matchLabels" -}}
  {{- $labels := include "common.labels.matchLabels" . | fromYaml -}}
  {{- if .context._include.component -}}
    {{- $_ := set $labels "app.kubernetes.io/component" .context._include.component -}}
  {{- end -}}
  {{- $labels | toYaml -}}
{{- end -}}