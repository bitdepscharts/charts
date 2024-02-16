{{/* vim: set filetype=mustache: */}}

{{/*
Defines the default resource metadata
*/}}
{{- define "raw.metadata" -}}
{{- $name := .name -}}
{{- with .context -}}
metadata:
  {{- if $name -}}
  name: {{ template "common.names.fullname" .context }}-{{ $name }}
  {{- end -}}
  namespace: {{ include "common.names.namespace" . | quote }}
  labels: {{- include "common.labels.standard" ( dict "customLabels" .Values.commonLabels "context" . ) | nindent 4 }}
  {{- if .Values.commonAnnotations }}
  annotations: {{- include "common.tplvalues.render" ( dict "value" .Values.commonAnnotations "context" . ) | nindent 4 }}
  {{- end }}
{{- end -}}
{{- end -}}

{{/*
Compile all warnings into a single message.
*/}}
{{- define "raw.validateValues" -}}
{{- $messages := list -}}
{{- $messages := append $messages (include "raw.validateValues.conditionSettings" .) -}}
{{- $messages := without $messages "" -}}
{{- $message := join "\n" $messages -}}

{{- if $message -}}
{{-   printf "\nVALUES VALIDATION:\n%s" $message -}}
{{- end -}}
{{- end -}}

{{/* Validate that enable and disable aren't used together  */}}
{{- define "raw.validateValues.conditionSettings" -}}
{{- if and (not (empty .Values.enable)) (not (empty .Values.disable)) -}}
raw: enable-disable-priority
    Both .Values.enable and .Values.disable are provided. Operating in enable
    mode, disable list is ignored. To swithch to disable mode enable list
    must be empty!
{{- end -}}
{{- end -}}
