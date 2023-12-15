{{/* vim: set filetype=helm: */}}
{{/*
Includes the given resource from the app chart templates.
Note that if component is not provided we assume it's default.

Usage
  {{- include "app.resource.include" (dict "_include" (dict "resource" "deployment" "top" $) }}
  {{- include "app.resource.include" (dict "_include" (dict "resource" "deployment" "component" "foo" "values" .Path.Values "top" $)) }}

  It also supports custom parameters, especially used during nested invocations such
  as in configmaps or secrets. Pay attention to mergeOverwrite since we need to
  overwrite existing the _include fields (including resource).

  {{- include "app.resources.include" (dict "_include" (dict "resource" "configmap" "name" $name "data" $data) | mergeOverwrite $) }}
*/}}
{{- define "app.resources.include" -}}
  {{/* Don't require top on nested runs, use _include.top */}}
  {{- if not (all ._include.resource ._include.top) -}}
    {{- "_include.{resource,top} must be provided" | fail -}}
  {{- end -}}
  {{- $top := ._include.top -}}
  {{- $config := $top.Values.app.components -}}

  {{- $component := ._include.component | default "default" -}}
  {{- $path := $config | dig $component "path" $component -}}
  {{- $enabled := $config | dig $component "enabled" "false" | toString -}}

  {{- if eq $enabled "true" -}}
    {{- $baseDefaults := $top.Files.Get "component-values.yaml" | fromYaml -}}
    {{- $componentValues := $top.Values -}}

    {{/* The default component always uses .Values */}}
    {{- $componentValues = ternary $top.Values (get $top.Values $path) (eq $component "default") -}}
    {{- if not (any $componentValues ._include.values) -}}
      {{- printf "Component %s must have values at .%s" $component $path | fail -}}
    {{- end -}}
    {{- $componentValues = ._include.values | default $componentValues | mergeOverwrite $baseDefaults -}}

    {{/* Specific global values are always injected into the render context */}}
    {{- $global := pick $top.Values "commonLabels" "commonAnnotations" "global" -}}
    {{- $values := $global | mergeOverwrite $componentValues -}}

    {{/* All other templates identify the default component as empty/unset */}}
    {{- $include := set ._include "component" (ternary nil $component (eq $component "default")) -}}
    {{- $context := omit $include.top "Values" | merge (dict "Values" $values "_include" $include) -}}
    {{- include (printf "app.resources.%s" $include.resource) $context  -}}
  {{- end -}}
{{- end -}}

{{/*
Function renders app resource template files (eg. deployments).
This performs a single or a batch render, if component is provided the batch
mode is used.

By placing the include statement into specificly named file you enable automatic
resource name detection, for example if placed into the deployment.yaml template
renders deployments.
Note that Helm provides you with file name location comments
(# Source .../templates/{resource}.yaml), which is useful to have.

Usage:
  Renderer: 1) automatic resource identification 2) all pvc 3) the default pvc
  {{- include "app.template" . -}}
  {{- include "app.template" (dict "resource" "pvc" "top" $) -}}
  {{- include "app.template" (dict "resource" "pvc" "component" "default" "values" .Path.to.values "top" $) -}}
```
*/}}
{{- define "app.template" -}}
  {{- $top := . | default .top -}}
  {{- $process := list -}}
  {{- $config := $top.Values.app.components -}}

  {{/* Pick the resource or detect automatically */}}
  {{- $defaultResource := .Template.Name | base | trimSuffix ".yaml" -}}
  {{- $resource := ternary $defaultResource .resource (empty .resource) -}}

  {{/* process all if .component is unset/empty */}}
  {{- $process := ternary (keys $config) (list .component) (empty .component) -}}
 
  {{- range $component := $process | sortAlpha -}}
    {{- $enabled := $config | dig $component "enabled" "false" | toString -}}
    {{- if eq $enabled "true" -}}
      {{/* define context */}}
      {{- $include := dict "resource" $resource "top" $top "values" $.values -}}
      {{- $context := dict "_include" ($include | merge (dict "component" $component)) -}}
      {{- include "app.resources.include" $context -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
