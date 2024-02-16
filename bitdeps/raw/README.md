# Bitdeps raw chart - a handy tool to generate raw Kubernetes manifests

The raw chart serves as a versatile tool for generating raw resources and templates. Its functionality extends beyond mere resource generation - it also offers a convenient interface for conditional rendering, allowing the chart to render multiple resources based on specific conditions.

## Introduction

This chart is simillar to charts such as:
  - [bedag/raw](https://artifacthub.io/packages/helm/main/raw)
  - [dysnix/raw](https://artifacthub.io/packages/helm/dysnix/raw)

However, it comes bundled with Bitnami Common and introduces features for conditional rendering. Another significant aspect is its provision of a configurable chart name, allowing you to migrate your existing charts that wrap simplistic manifests.

## TL;DR

```shell
helm install example oci://ghcr.io/bitdepscharts/raw --values config.yaml
```

## Source Code

* <https://github.com/bitdepscharts/charts/tree/main/bitdeps/raw>

## Parameters

### Raw App chart parameters

| Name                | Description                                                                       | Value |
| ------------------- | --------------------------------------------------------------------------------- | ----- |
| `chartName`         | Defines the chart/application (helm.sh/chart and app.kubernetes.io/name)          | `raw` |
| `nameOverride`      | String to partially override common.names.name (overrides app.kubernetes.io/name) | `""`  |
| `fullnameOverride`  | String to fully override common.names.fullname                                    | `""`  |
| `namespaceOverride` | String to fully override common.names.namespace                                   | `""`  |
| `commonLabels`      | Labels to add to all deployed objects                                             | `{}`  |
| `commonAnnotations` | Annotations to add to all deployed objects                                        | `{}`  |

### Conditional rendring parameters

| Name        | Description                                                                              | Value |
| ----------- | ---------------------------------------------------------------------------------------- | ----- |
| `features`  | List specifying available features (with can by enabled or disabled)                     | `[]`  |
| `enable`    | List to selectively enable features - enable mode (all features are disabled by default) | `[]`  |
| `disable`   | List to selectively disable features - disable mode (all feautures are on)               | `[]`  |
| `resources` | List of resources to render (inner templates are not processed)                          | `[]`  |
| `templates` | List of templates (same as resources, but their inner content is rendered)               | `[]`  |

## Configuration Examples

### Resources and Templates

Both resources and templates are responsible for rendering the provided data into manifests. While metadata is automatically handled, it's entirely possible to override it within the `value` block.

```yaml
myVariable: hello

resources:
  - name: bar
    value:
      apiVersion: v1
      kind: ConfigMap
      metadata:
        name: '{{ include "common.names.fullname" . }}-override'
      data:
        bar: |-
          {{ .Values.myVariable }} // This is not rendered for a resource.

templates:
  - name: foo
    value: |
      apiVersion: v1
      kind: ConfigMap
      data:
        foo: |-
          {{ .Values.myVariable }}
```

### Features: enable/disable mode

You may use `features`, `enable`, `disable` and `condition` to achieve conditional rendering follow on with the examples. If a resource or template has no condition specified a manifest will be unconditionally rendered!

#### Enable mode

Enable mode is turned on when `enable` list is provided, it disables all provided features except those specificly set in the `enable` list. In fact enable doesn't require features enumeration at all.

```yaml
features:
  - istio
  - kube-state-metrics
  - foo

enable:
  - foo

resources:
  - name: foo
    condition: foo.enabled
    value:
      apiVersion: v1
      kind: ConfigMap
      data:
        foo: bar
```

#### Disable mode

This mode is enabled when `disable` list is provided. It enables all features by default and disables only those which are specifically given by the `disable` list.

Note: if both `enable` and `disable` is provided, the chart switches operation into **enable mode**.

### Key Points

* Utilize `chartName` to migrate multiple wrapper charts with simplistic manifests. This allows you to switch to just a single **raw** chart and seamlessly replace existing wrapper charts deployments.
* You have the flexibility to use either a map or a string for the `value` block. Note that any value within the `value` block **must be valid serializable YAML**. Ensure that items containing templates are properly escaped, as demonstrated in the example with `data.bar`, `data.foo`, and `metadata.name` (the latter in single quotes represents a valid YAML string).
* The **metadata** block is rendered via *tpl* in both `resources` and `templates`. Explicitly provided metadata takes precedence over the convenient defaults provided by the chart.
* You may leverage state-of-the-art Bitnami Common template helpers :)