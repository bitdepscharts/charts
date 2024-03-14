{{/* vim: set filetype=mustache: */}}

{{/*
Pull secrets for .imagePullSecrets
*/}}
{{- define "raw.imagePullSecrets" -}}
{{- include "common.images.renderPullSecrets" (dict "global" .Values) -}}
{{- end -}}