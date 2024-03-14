# Bitdeps raw chart - a handy tool to generate raw Kubernetes manifests

The raw chart serves as a versatile tool for generating kubernets resources. Its functionality extends beyond mere resource generation - it also offers a convenient interface for conditional rendering, allowing the chart to render multiple resources based on specific conditions. Also it can load resources from files in your Helm chart.

## Introduction

This chart is similar to other charts such as:

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

| Name               | Description                                                     | Value  |
| ------------------ | --------------------------------------------------------------- | ------ |
| `features.enabled` | Specify whether to use the features.default state.              | `true` |
| `features.default` | Specify the feature default state (enabled/disabled)            | `{}`   |
| `rawList`          | List of resources to render (value can be either map or string) | `[]`   |

## Configuration Examples

### Handling Resources

The `rawList` list expects definitions of resources to render. Note that the value is rendered using Bitnami `common.tplvalue.render`, so the contents of variables will be substituted (the value can either map or string).

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
          {{ .Values.myVariable }}
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

When a condition such as `istio.enabled` is met, it matches this default state if `features.enabled: true`. You can explicitly enable/disable features (as `hello.enabled: true`), this specification has the priority over `features.default`, see the example below:

```yaml
features:
  default:
    hello: false

hello:
  enabled: true

rawList:
  - name: config
    condition: hello.enabled
    value:
      ...
```

Note: use `features.enabled: false` to disable the default features state.

## Advanced Usage

This chart supports operation as a dependency. In such a case, it provides the `raw.render.fromfiles` function, which you invoke as follows:

```yaml
{{- include "raw.render.fromfiles" (dict "resources" "scrapers/**.yaml" "values" .Values.scrapers "context" $) -}}
```

The `resources` parameter provides a file-glob to look up files in your root chart, while `values` is a path to features and their settings. These files contain resource templates which will be rendered with the only difference that you need to place configuration under `raw` parameter:

```yaml
# scrapers/istio.yaml
---
raw:
  condition: istio.enabled
  name: istio

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

Note: a single file may contain YAML-multipart documents to facilitate simultaneous rendering of multiple resources.

## Key Takeaways

- Utilize `chartName` to migrate multiple wrapper charts with simplistic manifests. This allows you to switch to just a single **raw** chart and seamlessly replace existing wrapper chart deployments.
- Chart **automatically generates metadata** such as `metadata.name`, `metadata.labels` etc. Explicitly provided metadata under `value` takes precedence.
- You have the flexibility to use either a map or a string for the `value` block. Note that any value within the `value` block **must be valid serializable YAML**. Ensure that items containing templates are properly escaped.
- You may leverage state-of-the-art Bitnami Common template helpers.
