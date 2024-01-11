<!-- markdownlint-disable-next-line -->
[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/bitdeps)](https://artifacthub.io/packages/search?org=bitdeps) [![CD Pipeline](https://github.com/bitdepscharts/charts/actions/workflows/release.yaml/badge.svg)](https://github.com/bitdepscharts/charts/actions/workflows/release.yaml)

# BitDeps Helm charts

This an OCI helm charts repositories, to install a desired chart use the command as bellow:

```bash
helm install my-release oci://ghcr.io/bitdepscharts/app
```

## Enable client githooks

**It's strongly advised to enable client-side .git/hooks!**

```bash
cat <<EHD > .git/hooks/pre-push
#!/bin/bash
set -e
repo_path="$(git rev-parse --show-toplevel)"

\${repo_path}/githooks/pre-push/chart-version
\${repo_path}/githooks/pre-push/helm-lint
\${repo_path}/githooks/pre-push/yaml-lint
\${repo_path}/githooks/pre-push/kubeval
EHD

chmod +x .git/hooks/pre-push
```
