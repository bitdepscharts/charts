{{/* vim: set filetype=mustache: */}}

{{/*
Pull secrets for .imagePullSecrets
{{ include "raw.imagePullSecrets" ( dict "images" (list .Values.path.to.the.image1, .Values.path.to.the.image2) "context" $) }}
*/}}
{{- define "raw.imagePullSecrets" -}}
{{- $context := $ -}}
{{- with .Values.imagePullSecrets -}}
  {{- $injectGlobal := merge $.Values (dict "global" (dict "imagePullSecrets" .)) -}}
  {{- $_ := set $context "Values" $injectGlobal -}}
{{- end -}}
{{- include "common.images.renderPullSecrets" (dict "context" $context) -}}
{{- end -}}
