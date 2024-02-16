{{/* vim: set filetype=mustache: */}}
{{- $fullName := include "common.names.fullname" . -}}
{{- $disabled := dict -}}
{{- $conditions := dict -}}
{{- $enableMode := not (empty .Values.enable) -}}
{{- $rendered := list -}}

{{/* Concat resources and templates */}}
{{- $input := list -}}
{{- range .Values.resources -}}{{- $input = append $input (set . "type" "resource")  -}}{{- end -}}
{{- range .Values.templates -}}{{- $input = append $input (set . "type" "template")  -}}{{- end -}}

{{/* Disable map <condition>: true */}}
{{- range .Values.disable -}}{{- $_ := set $disabled . true  -}}{{- end -}}

{{/* Select features, in enable mode all features are disabled by default */}}
{{- $features := ternary .Values.enable .Values.features $enableMode -}}

{{- range $features -}}
  {{- if $enableMode -}}
    {{- $_ := set $conditions (printf "%s.enabled" .) true -}}
  {{- else -}}
    {{- $bool := not (get $disabled . | default false) -}}
    {{- $_ := set $conditions (printf "%s.enabled" .) $bool -}}
  {{- end -}}
{{- end -}}

{{/* Build resulting rendered list */}}
{{- range $resource :=  $input -}}
  {{- if empty $resource.name -}}{{- fail "resource/template .name must be provided!" -}}{{- end -}}
  {{- $condition := $resource.condition | default "" -}}
  {{- $metadata := include "raw.metadata" (dict "name" $resource.name "context" $) | fromYaml -}}

  {{/* Add resource if condition is not specified (empty) or feature is enabled */}}
  {{- $bool := get $conditions $condition | default (not $enableMode) -}}
  {{- if or $bool (eq $condition "") -}}
    {{- with $resource -}}
      {{/* 
        Resource doesn't apply inner templating, however metadata is still rendered for
        convinence!
      */}}
      {{- if eq .type "resource" -}}
        {{- $valuemeta := dict -}}

        {{- $value := typeIs "string" .value | ternary .value (.value | toYaml) | fromYaml -}}              
        {{- with $value.metadata -}}
          {{- $valuemeta = dict "metadata" (include "common.tplvalues.render" (dict "value" . "context" $) | fromYaml) -}}
        {{- end -}}
        {{- $value := merge $valuemeta $value $metadata -}}
        {{- $rendered = append $rendered ($value | toYaml) -}}

      {{- else -}}
        {{- $value := include "common.tplvalues.render" (dict "value" .value "context" $) | fromYaml | mergeOverwrite $metadata  -}}
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