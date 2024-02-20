{{/* vim: set filetype=mustache: */}}

{{/*
  Render raw resources and templates

  {{- include "raw.render" (dict "resources" .Values.resources "values" $ "context" $) -}}
*/}}
{{- define "raw.render" -}}
  {{- $rendered := list -}}

  {{- with set .context "Values" .values -}}
    {{- $context := . -}}
    {{- range $.resources -}}

      {{- $type := .type | default "resource" -}}
      {{- $defaultMetadata := include "raw.metadata" (dict "name" .name "context" $context) | fromYaml -}}

      {{- if include "raw.feature.enabled" (dict "condition" .condition "context" $context) -}}

        {{/* Parse resource metadata */}}
        {{- $value := typeIs "string" .value | ternary .value (.value | toYaml) | fromYaml -}}
        {{- $metadata := dict -}}
        {{- with $value.metadata -}}
          {{- $metadata = include "common.tplvalues.render" (dict "value" . "context" $context | fromYaml) -}}
        {{- end -}}

        {{/* Build up value's resulting metadata */}}
        {{- $value = set $value "metadata" (merge $metadata $defaultMetadata) -}}
        {{- if not $value.metadata.name -}}{{- "Raw resources must either have name or value.metadta.name set!" | fail -}}{{- end -}}

        {{- if eq $type "resource" -}}
          {{- $rendered = append $rendered ($value | toYaml) -}}
        {{- else if eq $type "template" -}}
          {{- $value := include "common.tplvalues.render" (dict "value" .value "context" $context) | fromYaml | merge $metadata  -}}
          {{- $rendered = append $rendered ($value | toYaml) -}}
        {{- end -}}

      {{- end -}}
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
        {{- with . | fromYaml -}}
          {{- $resources = append $resources . -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}

  {{- end }}

  {{- if $resources -}}
    {{- include "raw.render" (dict "resources" $resources "values" .values "context" .context) -}}
  {{- end -}}
{{- end -}}
