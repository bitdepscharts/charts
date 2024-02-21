{{/* vim: set filetype=mustache: */}}

{{/*
Labels used on immutable fields such as deploy.spec.selector.matchLabels or svc.spec.selector
{{ include "raw.labels.matchLabels" (dict "customLabels" .Values.podLabels "context" $) -}}

We don't want to loop over custom labels appending them to the selector
since it's very likely that it will break deployments, services, etc.
However, it's important to overwrite the standard labels if the user
overwrote them on metadata.labels fields.

Raw enhancment: add legacy naming scheme support
*/}}
{{- define "raw.labels.matchLabels" -}}
  {{- $name := ternary "app" "app.kubernetes.io/name" (and (hasKey . "context") .legacy) -}}
  {{- $instance := ternary "release" "app.kubernetes.io/instance" (and (hasKey . "context") .legacy) -}}
{{- if and (hasKey . "customLabels") (hasKey . "context") -}}
{{ merge (pick (include "common.tplvalues.render" (dict "value" .customLabels "context" .context) | fromYaml) $name $instance) (dict $name (include "common.names.name" .context) $instance .context.Release.Name ) | toYaml }}
{{- else -}}
app.kubernetes.io/name: {{ include "common.names.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
{{- end -}}