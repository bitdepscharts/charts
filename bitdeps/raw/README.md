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

### Resources and features

| Name               | Description                                                                | Value  |
| ------------------ | -------------------------------------------------------------------------- | ------ |
| `features.enabled` | Specify whether to use the features.default state.                         | `true` |
| `features.default` | Specify the feature default state (enabled/disabled)                       | `{}`   |
| `rawList`          | List of resources to render (value is rendered using tpl if type=template) | `[]`   |

## Configuration Examples

### Handling Resources/Templates

The `rawList` list expects definitions of resources to render. Depending on the `type`, the raw chart will process the `value` differently. If `type: template`, the `value` will be subject to `tpl` rendering. If `type: resource` or not specified, no rendered as is.

```yaml
myVariable: hello
rawList:
- name: config
  value:
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: "overrides-automatic-fullname"
    data:
      bar: |-
        {{ .Values.myVariable }} // This is not rendered 'type: template' is not set.
```

### Features

The chart supports conditional rendering for a convenient way to enable/disable features. First, you may want to define defaults for the available features:

```yaml
features:
  enabled: true
  default:
    cadvisor: true
    kube-state-metrics: true
    kubernetes-nodes: true
    port-metrics: true
    istio: true
```

When a condition such as `istio.enabled` is met, it matches this default state if `features.enabled: true`. You can explicitly enable/disable features (as `hello.enabled: true`), this specification has the priority over `features.default`, see the example bellow:

```yaml
features:
  default:
    hello: false

hello:
  enabled: true

rawList:
- type: template
  name: config
  condition: hello.enabled
  value:
    ...
```

Note: use `features.enabled: false` to disable the default features state.

## Advanced usage

This chart supports operation as a depndency in such case it provides `raw.render.fromfiles` function, which you invoke as follows:

```yaml
{{- include "raw.render.fromfiles" (dict "resources" "scarpers/**.yaml" "values" .Values.scrapers "context" $) -}}
```

`resource` provides a file-glob to lookup files in your root chart, `values` is a path to features and their settings. These files will contain YAML defintions of the same structure as we have covered above:

```yaml
# scarpers/istio.yaml
---
condition: istio.enabled
name: istio
value:
  apiVersion: operator.victoriametrics.com/v1beta1
  kind: VMPodScrape
  spec:
    podMetricsEndpoints:
      - port: http-envoy-prom
        scheme: http
        path: /stats/prometheus
        targetPort: http-envoy-prom
        interval: 20s
        scrapeTimeout: 5s
        honorLabels: true
    namespaceSelector:
      any: false
      matchNames: [ "istio-system" ]
    selector:
      matchLabels:
        chart: gateways
```

Note: that a single file may contain YAML-multipart document to facilate simultaneously multiple resources in one file.

## Key Takeaways

* Utilize `chartName` to migrate multiple wrapper charts with simplistic manifests. This allows you to switch to just a single **raw** chart and seamlessly replace existing wrapper charts deployments.
* You have the flexibility to use either a map or a string for the `value` block. Note that any value within the `value` block **must be valid serializable YAML**. Ensure that items containing templates are properly escaped, as demonstrated in the example with `data.bar`, `data.foo`, and `metadata.name` (the latter in single quotes represents a valid YAML string).
* Explicitly provided metadata takes precedence over the convenient defaults provided by the chart.
* You may leverage state-of-the-art Bitnami Common template helpers :)
