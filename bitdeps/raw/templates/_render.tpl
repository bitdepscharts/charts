{{/* vim: set filetype=mustache: */}}

{{/*
  Render raw resources and templates

  {{- include "raw.render" (dict "resources" .Values.resources "values" $ "context" $) -}}
*/}}
{{- define "raw.render" -}}
  {{- $rendered := list -}}
  {{- $context := dict "Values" .values | merge (omit .context "Values") -}}

  {{- range $.resources -}}
    {{- if include "raw.feature.enabled" (dict "condition" .condition "context" $context) -}}
      {{- $metadata := include "raw.metadata" (dict "name" .name "context" $context) | fromYaml -}}
      {{- $value := include "common.tplvalues.render" (dict "value" .value "context" $context) | fromYaml -}}

      {{- if and $value.metadata (typeIs "string" $value.metadata) -}}
        {{/* Fetch the resource metadata and merge with the automatic default */}}
        {{- $metadata = include "common.tplvalues.render" (dict "value" $value.metadata "context" $context | fromYaml) | mergeOverwrite $metadata -}}
      {{- end -}}
      {{- if not $metadata.name -}}{{- "Raw resources must either have name or value.metadta.name set!" | fail -}}{{- end -}}


      {{- $value = set $value "metadata" $metadata -}}
      {{- $rendered = append $rendered ($value | toYaml) -}}
    {{- end -}}
  {{- end -}}

{{/* Write the result */}}
{{- range $rendered }}
---
{{ . }}
{{- end }}
{{- end -}}

{{/*
Load resources and templates from chart files
{{- include "raw.render.fromfiles" (dict "resources" "scarpers/**.yaml" "values" .Values.mywrap "context" $) -}}
*/}}
{{- define "raw.render.fromfiles" -}}
  {{- $resources := list -}}
  {{- $glob := .resources | default "" -}}
  {{- if $glob -}}

    {{/* Load files specified by glob and split its contents by multipart separator --- */}}
    {{- range $path, $_ :=  $.context.Files.Glob $glob -}}
      {{- range $.context.Files.Get $path | splitList "---\n" -}}
        {{- with tpl . $.context | fromYaml -}}
          {{- $raw := .raw | default dict -}}
          {{- $resources = append $resources (dict "value" (omit . "raw") | merge $raw) -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}

  {{- end }}

  {{- if $resources -}}
    {{- include "raw.render" (dict "resources" $resources "values" .values "context" .context) -}}
  {{- end -}}
{{- end -}}
