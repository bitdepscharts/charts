{{/* vim: set filetype=mustache: */}}

{{/*
Defines the default resource metadata
*/}}
{{- define "raw.metadata" -}}
{{- with .context -}}

{{- if $.name }}
name: {{ template "common.names.fullname" . }}-{{ $.name }}
{{- end }}
namespace: {{ include "common.names.namespace" . | quote }}
labels: {{- include "common.labels.standard" ( dict "customLabels" .Values.commonLabels "context" . ) | nindent 4 }}
{{- if .Values.commonAnnotations }}
annotations: {{- include "common.tplvalues.render" ( dict "value" .Values.commonAnnotations "context" . ) | nindent 4 }}
{{- end }}

{{- end -}}
{{- end -}}

{{/*
Defines the default resource metadata
*/}}
{{- define "raw.feature.enabled" -}}
  {{- if not .condition }}
true
  {{- else -}}
    {{/* istio.enabled splits into _0: istio, _1: enabled */}}
    {{- $feature := .condition | split "." -}}
    {{- with .context -}}
      {{- $featureDefault := get .Values.defaultFeatures $feature._0 | default false -}}
      {{- $default := ternary $featureDefault false .Values.enableFeatures -}}
      {{- $enabled := .Values | dig  $feature._0 $feature._1 $default -}}
{{- ternary "true" "" $enabled -}}
    {{- end -}}
  {{- end }}
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
